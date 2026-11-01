import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
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
  static const int _maxControlMessagesPerSecond = 5;

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
  Timer? _controlPumpTimer;

  Set<String> _desired = {};
  Set<String> _active = {};
  final List<_PendingControlOp> _pendingOps = [];
  final List<_ControlMessage> _controlOutbox = [];
  final List<DateTime> _controlSentAt = [];

  int _controlMessageId = 1;
  int _backoffAttempt = 0;
  RealtimeStatus _status = const RealtimeStatus.offline();
  bool _disposed = false;
  bool _flushEnabled = false;
  bool _reconnecting = false;

  double? _eurUsdtRate;
  final Map<String, _RawTick> _latestRaw = {};
  final Map<String, PriceTick> _lastFlushed = {};

  @override
  Stream<PriceTick> get ticks => _ticksController.stream;

  @override
  Stream<RealtimeStatus> get status => _statusController.stream;

  @override
  RealtimeStatus get currentStatus => _status;

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
    _controlPumpTimer?.cancel();
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
      _debounceTimer?.cancel();
      _debounceTimer = null;
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
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _reconnectTimer?.cancel();
    _reconnecting = false;
    _eurUsdtRate = null;
    _emitStatus(const RealtimeStatus.connecting());
    _pauseLivePipeline(clearRaw: true);
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
    _flushEnabled = true;
    _startFlushTimer();
    _applySubscriptionDiff(initial: true);
    _emitStatus(const RealtimeStatus.degraded());
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
      _enqueueControl(method: 'UNSUBSCRIBE', symbols: toRemove);
    }
    if (toAdd.isNotEmpty) {
      _enqueueControl(method: 'SUBSCRIBE', symbols: toAdd);
    }
  }

  void _enqueueControl({required String method, required Set<String> symbols}) {
    if (symbols.isEmpty) {
      return;
    }
    final id = _controlMessageId++;
    _pendingOps.add(
      _PendingControlOp(method: method, symbols: symbols, id: id),
    );
    _controlOutbox.add(
      _ControlMessage(method: method, symbols: symbols, id: id),
    );
    _scheduleControlPump();
  }

  void _scheduleControlPump() {
    _controlPumpTimer ??= Timer.periodic(
      const Duration(milliseconds: 210),
      (_) => _pumpControlOutbox(),
    );
    _pumpControlOutbox();
  }

  void _pumpControlOutbox() {
    if (_disposed || _channel == null || _controlOutbox.isEmpty) {
      return;
    }
    final now = DateTime.now();
    _controlSentAt.removeWhere(
      (sentAt) => now.difference(sentAt) > const Duration(seconds: 1),
    );
    while (_controlOutbox.isNotEmpty &&
        _controlSentAt.length < _maxControlMessagesPerSecond) {
      final message = _controlOutbox.removeAt(0);
      _sendControlNow(message);
      _controlSentAt.add(now);
    }
    if (_controlOutbox.isEmpty) {
      _controlPumpTimer?.cancel();
      _controlPumpTimer = null;
    }
  }

  void _sendControlNow(_ControlMessage message) {
    final params = message.symbols
        .map((s) => '$s$_tickerSuffix')
        .toList(growable: false);
    final payload = jsonEncode({
      'method': message.method,
      'params': params,
      'id': message.id,
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
        if (decoded.containsKey('id') &&
            (decoded.containsKey('result') || decoded.containsKey('error'))) {
          _handleControlResponse(decoded);
          return;
        }
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
    _handleTickerPayload(payload);
  }

  void _handleControlResponse(Map<String, dynamic> payload) {
    final id = payload['id'] as int?;
    if (id == null) {
      return;
    }
    final opIndex = _pendingOps.indexWhere((op) => op.id == id);
    if (opIndex < 0) {
      return;
    }
    final op = _pendingOps.removeAt(opIndex);
    final error = payload['error'];
    if (error != null) {
      developer.log(
        'Binance control ${op.method} failed (id=$id): $error',
        name: 'PriceStreamService',
      );
      _active = {};
      _pendingOps.clear();
      _controlOutbox.clear();
      _applySubscriptionDiff(initial: true);
      return;
    }
    switch (op.method) {
      case 'SUBSCRIBE':
        _active.addAll(op.symbols);
      case 'UNSUBSCRIBE':
        _active.removeAll(op.symbols);
    }
  }

  void _handleTickerPayload(Map<String, dynamic> payload) {
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
      _maybePromoteToLive();
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
    _maybePromoteToLive();
  }

  void _maybePromoteToLive() {
    if (_eurUsdtRate == null || _eurUsdtRate! <= 0) {
      if (_status is! RealtimeDegraded && _status is! RealtimeOffline) {
        _emitStatus(const RealtimeStatus.degraded());
      }
      return;
    }
    if (_status is! RealtimeLive) {
      _emitStatus(const RealtimeStatus.live());
      _armStableReset();
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
    if (_disposed ||
        !_flushEnabled ||
        _reconnecting ||
        _channel == null ||
        _eurUsdtRate == null ||
        _eurUsdtRate! <= 0) {
      return;
    }
    for (final entry in _latestRaw.entries) {
      final raw = entry.value;
      final symbolUpper = entry.key.toUpperCase();
      final eurPrice = raw.usdtPrice / _eurUsdtRate!;
      final tick = PriceTick(
        symbol: symbolUpper,
        lastPriceUsdt: raw.usdtPrice,
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
    _reconnecting = true;
    _pauseLivePipeline(clearRaw: true);
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

  void _pauseLivePipeline({required bool clearRaw}) {
    _flushEnabled = false;
    _flushTimer?.cancel();
    _flushTimer = null;
    if (clearRaw) {
      _latestRaw.clear();
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _teardownConnection({required bool emitOffline}) {
    _pauseLivePipeline(clearRaw: true);
    _teardownChannelOnly();
    _lastFlushed.clear();
    _eurUsdtRate = null;
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
    _pendingOps.clear();
    _controlOutbox.clear();
    _controlSentAt.clear();
    _controlPumpTimer?.cancel();
    _controlPumpTimer = null;
    _staleTimer?.cancel();
    _stableResetTimer?.cancel();
  }

  /// Stale detection relies on **JSON `@ticker` traffic** on [StreamChannel.stream].
  /// Binance server **ping frames** on `IOWebSocketChannel` do not always appear here;
  /// with active subscriptions, `@ticker` (~1s) keeps this timer fresh.
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

class _PendingControlOp {
  _PendingControlOp({
    required this.method,
    required this.symbols,
    required this.id,
  });

  final String method;
  final Set<String> symbols;
  final int id;
}

class _ControlMessage {
  _ControlMessage({
    required this.method,
    required this.symbols,
    required this.id,
  });

  final String method;
  final Set<String> symbols;
  final int id;
}
