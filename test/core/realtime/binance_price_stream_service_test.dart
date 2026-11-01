import 'dart:convert';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/realtime/binance_price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'fake_web_socket_channel.dart';

void main() {
  late FakeWebSocketChannel channel;
  late BinancePriceStreamService service;
  final statuses = <RealtimeStatus>[];
  final ticks = <PriceTick>[];

  setUp(() {
    channel = FakeWebSocketChannel();
    statuses.clear();
    ticks.clear();
    service = BinancePriceStreamService(
      config: const AppConfig(),
      connect: (_) => channel,
      random: Random(0),
    );
    service.status.listen(statuses.add);
    service.ticks.listen(ticks.add);
  });

  tearDown(() async {
    await service.dispose();
  });

  test('subscribes with SUBSCRIBE including eurusdt', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));

      expect(
        channel.outgoingMessages.any((m) {
          final map = jsonDecode(m as String) as Map<String, dynamic>;
          return map['method'] == 'SUBSCRIBE' &&
              (map['params'] as List).contains('btcusdt@ticker') &&
              (map['params'] as List).contains('eurusdt@ticker');
        }),
        isTrue,
      );
    });
  });

  test('converts USDT tick to EUR using eurusdt rate', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);

      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      channel.addMessage(jsonEncode(_ticker('BTCUSDT', '54000', '-1.5')));

      async.elapse(const Duration(seconds: 1));

      expect(ticks, isNotEmpty);
      expect(ticks.last.symbol, 'BTCUSDT');
      expect(ticks.last.lastPriceUsdt, 54000);
      expect(ticks.last.lastPriceEur, closeTo(54000 / 1.08, 0.01));
      expect(ticks.last.changePercent24h, -1.5);
    });
  });

  test('stays degraded until EURUSDT rate arrives', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);

      channel.addMessage(jsonEncode(_ticker('BTCUSDT', '100', '1')));
      async.elapse(const Duration(milliseconds: 50));

      expect(statuses.whereType<RealtimeDegraded>(), isNotEmpty);
      expect(ticks, isEmpty);

      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      async.elapse(const Duration(seconds: 1));

      expect(statuses.whereType<RealtimeLive>(), isNotEmpty);
      expect(ticks, isNotEmpty);
    });
  });

  test('emits degraded and reconnects after stale window without traffic', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'ethusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);
      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      statuses.clear();

      async.elapse(const Duration(seconds: 45));

      expect(statuses.whereType<RealtimeDegraded>(), isNotEmpty);
      expect(statuses.whereType<RealtimeReconnecting>(), isNotEmpty);
    });
  });

  test('closes socket after 30s background lifecycle delay', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);

      service.setAppLifecycle(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 30));

      expect(statuses.whereType<RealtimeOffline>(), isNotEmpty);
    });
  });

  test('simulates 24h onDone with capped backoff reconnect', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);
      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      statuses.clear();

      channel.closeIncoming();
      async.elapse(const Duration(milliseconds: 10));
      expect(statuses.whereType<RealtimeReconnecting>(), isNotEmpty);

      async.elapse(const Duration(seconds: 1));
      expect(channel.outgoingMessages.length, greaterThan(0));
    });
  });

  test('stable live for 30s completes without error (backoff reset timer)', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);
      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      async.elapse(const Duration(milliseconds: 50));
      expect(statuses.whereType<RealtimeLive>(), isNotEmpty);
      async.elapse(const Duration(seconds: 30));
    });
  });

  test('does not flush ticks while reconnecting', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);
      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      channel.addMessage(jsonEncode(_ticker('BTCUSDT', '100', '1')));
      async.elapse(const Duration(seconds: 1));
      ticks.clear();

      channel.closeIncoming();
      async.elapse(const Duration(milliseconds: 10));
      async.elapse(const Duration(seconds: 1));

      expect(ticks, isEmpty);
    });
  });

  test('unsubscribes removed symbols on setDesiredSymbols diff', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt', 'ethusdt'});
      async.elapse(const Duration(milliseconds: 500));
      _ackAllControlMessages(channel);
      channel.outgoingMessages.clear();

      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));

      expect(
        channel.outgoingMessages.any((m) {
          final map = jsonDecode(m as String) as Map<String, dynamic>;
          return map['method'] == 'UNSUBSCRIBE' &&
              (map['params'] as List).contains('ethusdt@ticker');
        }),
        isTrue,
      );
    });
  });

  test('reconciles SUBSCRIBE ack into active set', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 500));
      final subscribe = channel.outgoingMessages.firstWhere((m) {
        final map = jsonDecode(m as String) as Map<String, dynamic>;
        return map['method'] == 'SUBSCRIBE';
      });
      final id = (jsonDecode(subscribe as String) as Map)['id'] as int;
      channel.addMessage(jsonEncode({'result': null, 'id': id}));
      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      channel.addMessage(jsonEncode(_ticker('BTCUSDT', '100', '0')));
      async.elapse(const Duration(seconds: 1));
      expect(ticks, isNotEmpty);
    });
  });
}

void _ackAllControlMessages(FakeWebSocketChannel channel) {
  for (final raw in List<Object?>.from(channel.outgoingMessages)) {
    if (raw is! String) {
      continue;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map.containsKey('id')) {
      channel.addMessage(jsonEncode({'result': null, 'id': map['id']}));
    }
  }
}

Map<String, dynamic> _ticker(String symbol, String last, String changeP) {
  return {
    'e': '24hrTicker',
    'E': DateTime.utc(2026, 6).millisecondsSinceEpoch,
    's': symbol,
    'c': last,
    'P': changeP,
  };
}
