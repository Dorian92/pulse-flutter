import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Binance `@ticker` implementation of [PriceStreamService].
class BinancePriceStreamService implements PriceStreamService {
  /// Creates the service.
  BinancePriceStreamService({
    required AppConfig config,
    StreamChannel<Object?> Function(Uri uri)? connect,
    Random? random,
  }) : _config = config,
       _connect = connect ?? ((uri) => WebSocketChannel.connect(uri)),
       _random = random ?? Random();

  static const String _eurPair = 'eurusdt';
  static const String _tickerSuffix = '@ticker';

  final AppConfig _config;
  final StreamChannel<Object?> Function(Uri uri) _connect;
  final Random _random;

  final StreamController<PriceTick> _ticksController =
      StreamController<PriceTick>.broadcast();
  final StreamController<RealtimeStatus> _statusController =
      StreamController<RealtimeStatus>.broadcast();

  StreamChannel<Object?>? _channel;
  StreamSubscription<Object?>? _channelSub;
  Timer? _flushTimer;
  Timer? _debounceTimer;
  Timer? _reconnectTimer;
  Timer? _backgroundTimer;
  Timer? _staleTimer;
  Timer? _stableResetTimer;

  Set<String> _desired = {};
  Set<String> _active = {};
  int _controlMessageId = 1;
  int _backoffAttempt = 0;
  RealtimeStatus _status = const RealtimeStatus.offline();
  bool _disposed = false;

  double? _eurUsdtRate;
  final Map<String, _RawTick> _latestRaw = {};
  final Map<String, PriceTick> _lastFlushed = {};

  @override
  Stream<PriceTick> get ticks => _ticksController.stream;

  @override
  Stream<RealtimeStatus> get status => _statusController.stream;

  @override
  void setDesiredSymbols(Set<String> lowercaseBinanceSymbols) {
    if (_disposed) {
      return;
    }
    final normalized = lowercaseBinanceSymbols
        .map((s) => s.toLowerCase())
        .where((s) => s.isNotEmpty && s != _eurPair)
        .toSet();
    if (setEquals(_desired, normalized)) {
      return;
    }
    _desired = normalized;
    _scheduleSubscriptionSync();
  }

  @override
  void setAppLifecycle(AppLifecycleState state) {
    if (_disposed || _config.disableRealtimeLifecycleTeardown) {
      return;
    }
    _backgroundTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      _scheduleSubscriptionSync(forceReconnect: true);
      return;
    }
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundTimer = Timer(_config.realtimeBackgroundDisconnectDelay, () {
        _teardownConnection(emitOffline: true);
      });
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _backgroundTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _flushTimer?.cancel();
    _staleTimer?.cancel();
    _stableResetTimer?.cancel();
    await _channelSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _ticksController.close();
    await _statusController.close();
  }

  void _scheduleSubscriptionSync({bool forceReconnect = false}) {
    if (_disposed) {
      return;
    }
    if (_desired.isEmpty) {
      _teardownConnection(emitOffline: true);
      return;
    }
    if (_channel == null || forceReconnect) {
      _connectSocket();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      _config.realtimeSubscribeDebounce,
      _applySubscriptionDiff,
    );
  }

  void _connectSocket() {
    if (_disposed || _desired.isEmpty) {
      return;
    }
    _reconnectTimer?.cancel();
    _emitStatus(const RealtimeStatus.connecting());
    _teardownChannelOnly();
    final uri = Uri.parse(_config.binanceWebSocketUrl);
    _channel = _connect(uri);
    _armStaleTimer();
    _channelSub = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _handleDisconnect(),
      onDone: _handleDisconnect,
      cancelOnError: false,
    );
    _startFlushTimer();
    _applySubscriptionDiff(initial: true);
  }

  void _applySubscriptionDiff({bool initial = false}) {
    if (_disposed || _channel == null) {
      return;
    }
    final target = {..._desired, _eurPair};
    final toAdd = target.difference(_active);
    final toRemove = _active.difference(target);
    if (toAdd.isEmpty && toRemove.isEmpty && !initial) {
      return;
    }
    if (toRemove.isNotEmpty) {
      _sendControl(method: 'UNSUBSCRIBE', symbols: toRemove);
      _active.removeAll(toRemove);
    }
    if (toAdd.isNotEmpty) {
      _sendControl(method: 'SUBSCRIBE', symbols: toAdd);
      _active.addAll(toAdd);
    }
  }

  void _sendControl({required String method, required Set<String> symbols}) {
    final params = symbols
        .map((s) => '$s$_tickerSuffix')
        .toList(growable: false);
    final payload = jsonEncode({
      'method': method,
      'params': params,
      'id': _controlMessageId++,
    });
    _channel?.sink.add(payload);
  }

  void _onMessage(Object? message) {
    if (_disposed) {
      return;
    }
    _armStaleTimer();
    final text = message is String
        ? message
        : utf8.decode(message as List<int>);
    if (text == 'ping') {
      _channel?.sink.add('pong');
      return;
    }
    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data') &&
            decoded['data'] is Map<String, dynamic>) {
          payload = decoded['data'] as Map<String, dynamic>;
        } else {
          payload = decoded;
        }
      }
    } on FormatException {
      return;
    }
    if (payload == null) {
      return;
    }
    if (payload['e'] != '24hrTicker') {
      return;
    }
    final symbol = (payload['s'] as String?)?.toUpperCase();
    final lastPrice = double.tryParse(payload['c'] as String? ?? '');
    final eventMs = payload['E'] as int?;
    if (symbol == null || lastPrice == null || eventMs == null) {
      return;
    }
    final eventTime = DateTime.fromMillisecondsSinceEpoch(eventMs, isUtc: true);
    final changePercent = double.tryParse(payload['P'] as String? ?? '');

    if (symbol == _eurPair.toUpperCase()) {
      _eurUsdtRate = lastPrice;
      if (_status is! RealtimeLive) {
        _emitStatus(const RealtimeStatus.live());
        _armStableReset();
      }
      return;
    }

    final lowercase = symbol.toLowerCase();
    if (!_desired.contains(lowercase)) {
      return;
    }

    _latestRaw[lowercase] = _RawTick(
      usdtPrice: lastPrice,
      changePercent24h: changePercent,
      eventTime: eventTime,
    );

    if (_status is! RealtimeLive && _status is! RealtimeDegraded) {
      _emitStatus(const RealtimeStatus.live());
      _armStableReset();
    } else if (_status is RealtimeDegraded) {
      _emitStatus(const RealtimeStatus.live());
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      _config.realtimeTickThrottle,
      (_) => _flushTicks(),
    );
  }

  void _flushTicks() {
    if (_disposed || _eurUsdtRate == null || _eurUsdtRate! <= 0) {
      return;
    }
    for (final entry in _latestRaw.entries) {
      final raw = entry.value;
      final symbolUpper = entry.key.toUpperCase();
      final eurPrice = raw.usdtPrice / _eurUsdtRate!;
      final tick = PriceTick(
        symbol: symbolUpper,
        lastPriceEur: eurPrice,
        changePercent24h: raw.changePercent24h,
        eventTime: raw.eventTime,
      );
      final previous = _lastFlushed[entry.key];
      if (previous != null &&
          previous.lastPriceEur == tick.lastPriceEur &&
          previous.changePercent24h == tick.changePercent24h) {
        continue;
      }
      _lastFlushed[entry.key] = tick;
      _ticksController.add(tick);
    }
  }

  void _handleDisconnect() {
    if (_disposed) {
      return;
    }
    _teardownChannelOnly();
    if (_desired.isEmpty) {
      _emitStatus(const RealtimeStatus.offline());
      return;
    }
    _emitStatus(const RealtimeStatus.reconnecting());
    final baseMs = min(
      _config.realtimeBackoffCap.inMilliseconds,
      1000 * (1 << _backoffAttempt.clamp(0, 6)),
    );
    _backoffAttempt++;
    final jitterMs = _random.nextInt(500);
    _reconnectTimer = Timer(Duration(milliseconds: baseMs + jitterMs), () {
      if (!_disposed && _desired.isNotEmpty) {
        _connectSocket();
      }
    });
  }

  void _teardownConnection({required bool emitOffline}) {
    _teardownChannelOnly();
    _flushTimer?.cancel();
    _flushTimer = null;
    _latestRaw.clear();
    _lastFlushed.clear();
    if (emitOffline) {
      _emitStatus(const RealtimeStatus.offline());
    }
  }

  void _teardownChannelOnly() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _active = {};
    _staleTimer?.cancel();
    _stableResetTimer?.cancel();
  }

  void _armStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(_config.realtimeStaleAfter, () {
      if (_disposed || _desired.isEmpty) {
        return;
      }
      _emitStatus(const RealtimeStatus.degraded());
      _handleDisconnect();
    });
  }

  void _armStableReset() {
    _stableResetTimer?.cancel();
    _stableResetTimer = Timer(_config.realtimeStableResetBackoff, () {
      _backoffAttempt = 0;
    });
  }

  void _emitStatus(RealtimeStatus next) {
    if (_status == next) {
      return;
    }
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }
}

class _RawTick {
  _RawTick({
    required this.usdtPrice,
    required this.eventTime,
    this.changePercent24h,
  });

  final double usdtPrice;
  final double? changePercent24h;
  final DateTime eventTime;
}

bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final value in a) {
    if (!b.contains(value)) {
      return false;
    }
  }
  return true;
}
