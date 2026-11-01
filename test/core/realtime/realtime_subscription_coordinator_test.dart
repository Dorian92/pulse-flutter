import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'fake_price_stream_service.dart';

void main() {
  test('merges token sets into union for price stream', () {
    final fake = FakePriceStreamService();
    final coordinator = RealtimeSubscriptionCoordinator(fake);

    coordinator.setSymbols('markets', {'btcusdt', 'ethusdt'});
    coordinator.setSymbols('watchlist', {'ethusdt', 'solusdt'});

    expect(fake.lastDesiredSymbols, equals({'btcusdt', 'ethusdt', 'solusdt'}));

    coordinator.removeToken('watchlist');
    expect(fake.lastDesiredSymbols, equals({'btcusdt', 'ethusdt'}));
  });
}
