import 'dart:convert';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
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

  setUp(() {
    channel = FakeWebSocketChannel();
    statuses.clear();
    service = BinancePriceStreamService(
      config: const AppConfig(disableRealtimeLifecycleTeardown: true),
      connect: (_) => channel,
      random: Random(0),
    );
    service.status.listen(statuses.add);
  });

  tearDown(() async {
    await service.dispose();
  });

  test('subscribes with SUBSCRIBE including eurusdt', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 250));

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
      PriceTick? tick;
      service.ticks.listen((event) => tick = event);

      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 250));

      channel.addMessage(jsonEncode(_ticker('EURUSDT', '1.08', '0')));
      channel.addMessage(jsonEncode(_ticker('BTCUSDT', '54000', '-1.5')));

      async.elapse(const Duration(seconds: 1));

      expect(tick, isNotNull);
      expect(tick!.symbol, 'BTCUSDT');
      expect(tick!.lastPriceEur, closeTo(54000 / 1.08, 0.01));
      expect(tick!.changePercent24h, -1.5);
    });
  });

  test('emits reconnecting status when socket closes', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'ethusdt'});
      async.elapse(const Duration(milliseconds: 250));
      statuses.clear();

      channel.closeIncoming();
      async.elapse(const Duration(milliseconds: 10));

      expect(statuses, contains(isA<RealtimeReconnecting>()));
    });
  });

  test('unsubscribes removed symbols on setDesiredSymbols diff', () {
    fakeAsync((async) {
      service.setDesiredSymbols({'btcusdt', 'ethusdt'});
      async.elapse(const Duration(milliseconds: 250));
      channel.outgoingMessages.clear();

      service.setDesiredSymbols({'btcusdt'});
      async.elapse(const Duration(milliseconds: 250));

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
}

Map<String, dynamic> _ticker(String symbol, String last, String changeP) {
  return {
    'e': '24hrTicker',
    'E': DateTime.utc(2026, 6, 1).millisecondsSinceEpoch,
    's': symbol,
    'c': last,
    'P': changeP,
  };
}
