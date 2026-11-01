import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';

void main() {
  test('parseMarketCoinFromApi maps sparkline and SymbolMapper', () {
    final fixture = File(
      'test/markets/fixtures/coingecko_markets_page1.json',
    ).readAsStringSync();
    final list = json.decode(fixture) as List<dynamic>;
    final bitcoin = list.first as Map<String, dynamic>;
    final unknown = list.last as Map<String, dynamic>;

    final mapper = SymbolMapper();
    final btc = parseMarketCoinFromApi(bitcoin, symbolMapper: mapper);
    expect(btc.id, 'bitcoin');
    expect(btc.sparkline7d, [90000, 91000, 95000]);
    expect(btc.binanceSymbol, 'BTCUSDT');

    final unk = parseMarketCoinFromApi(unknown, symbolMapper: mapper);
    expect(unk.id, 'unknown-alt');
    expect(unk.binanceSymbol, isNull);
    expect(unk.hasLiveFeed, isFalse);
  });

  test('parseGlobalMarketSummaryFromApi uses EUR only', () {
    final fixture = File(
      'test/markets/fixtures/coingecko_global.json',
    ).readAsStringSync();
    final jsonMap = json.decode(fixture) as Map<String, dynamic>;

    final summary = parseGlobalMarketSummaryFromApi(jsonMap, vsCurrency: 'eur');
    expect(summary.totalMarketCapEur, 2310000000000);
    expect(summary.hasMarketCap, isTrue);
    expect(summary.marketCapChangePercent24h, 1.8);
  });

  test('parseGlobalMarketSummaryFromApi omits USD fallback', () {
    final summary = parseGlobalMarketSummaryFromApi({
      'data': {
        'total_market_cap': {'usd': 2500000000000},
        'market_cap_change_percentage_24h_usd': 2,
      },
    }, vsCurrency: 'eur');
    expect(summary.totalMarketCapEur, isNull);
    expect(summary.hasMarketCap, isFalse);
    expect(summary.marketCapChangePercent24h, 2);
  });

  test('MarketCoin copyWith updates live fields', () {
    const coin = MarketCoin(
      id: 'bitcoin',
      symbol: 'btc',
      name: 'Bitcoin',
      imageUrl: '',
      currentPriceEur: 1,
      priceChangePercent24h: 0,
      marketCapRank: 1,
      sparkline7d: [1],
    );
    final tick = DateTime.utc(2026, 6, 1, 12);
    final updated = coin.copyWith(
      currentPriceEur: 2,
      priceChangePercent24h: 3,
      lastLiveTickAt: tick,
    );
    expect(updated.currentPriceEur, 2);
    expect(updated.priceChangePercent24h, 3);
    expect(updated.lastLiveTickAt, tick);
    expect(updated.id, coin.id);
  });
}
