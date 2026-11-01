import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';

void main() {
  test('MarketCoin parses sparkline and round-trips JSON', () {
    final fixture = File(
      'test/markets/fixtures/coingecko_markets_page1.json',
    ).readAsStringSync();
    final list = json.decode(fixture) as List<dynamic>;
    final raw = list.first as Map<String, dynamic>;
    final sparklineMap = raw['sparkline_in_7d'] as Map<String, dynamic>;
    final prices = (sparklineMap['price'] as List).cast<num>();

    final coin = MarketCoin(
      id: raw['id'] as String,
      symbol: raw['symbol'] as String,
      name: raw['name'] as String,
      imageUrl: raw['image'] as String,
      currentPriceEur: (raw['current_price'] as num).toDouble(),
      priceChangePercent24h: (raw['price_change_percentage_24h'] as num)
          .toDouble(),
      marketCapRank: raw['market_cap_rank'] as int,
      sparkline7d: prices.map((e) => e.toDouble()).toList(),
    );

    final decoded = MarketCoin.fromJson(coin.toJson());
    expect(decoded, coin);
    expect(decoded.sparkline7d, [90000, 91000, 95000]);
  });

  test('MarketsSnapshot fromJson uses fetchedAt', () {
    final snapshot = MarketsSnapshot.fromJson({
      'fetchedAt': '2026-06-01T12:00:00.000Z',
      'global': {'totalMarketCapEur': 100, 'marketCapChangePercent24h': 1},
      'coins': [
        {
          'id': 'bitcoin',
          'symbol': 'btc',
          'name': 'Bitcoin',
          'imageUrl': '',
          'currentPriceEur': 1,
          'priceChangePercent24h': 0,
          'marketCapRank': 1,
          'sparkline7d': [1, 2],
        },
      ],
    });

    expect(snapshot.coins, hasLength(1));
    expect(snapshot.fetchedAt, DateTime.utc(2026, 6, 1, 12));
  });
}
