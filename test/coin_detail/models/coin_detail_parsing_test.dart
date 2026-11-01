import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';

void main() {
  test('parseCoinDetailFromApi strips HTML and maps EUR fields', () async {
    final raw = await File(
      'test/coin_detail/fixtures/coingecko_coin_bitcoin.json',
    ).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final detail = parseCoinDetailFromApi(
      json,
      coinId: 'bitcoin',
      symbolMapper: SymbolMapper(),
      fetchedAt: DateTime.utc(2026, 1, 1),
    );

    expect(detail.id, 'bitcoin');
    expect(detail.symbol, 'BTC');
    expect(detail.currentPriceEur, 65000.5);
    expect(detail.priceChangePercent24h, 2.41);
    expect(detail.binanceSymbol, 'BTCUSDT');
    expect(detail.aboutTextEn, 'Bitcoin is digital gold.');
    expect(stripHtmlDescription('<a href="#">x</a>'), 'x');
  });
}
