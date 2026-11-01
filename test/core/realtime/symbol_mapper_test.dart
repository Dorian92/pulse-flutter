import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';

void main() {
  final mapper = SymbolMapper();

  test('maps known CoinGecko ids', () {
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'bitcoin'), 'BTCUSDT');
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'ethereum'), 'ETHUSDT');
  });

  test('returns null when id is not in the static map', () {
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'obscure-id'), isNull);
  });

  test('resolves via exchange base asset map', () {
    final mapper = SymbolMapper()..applyExchangeBaseAssets({'SOL': 'SOLUSDT'});
    expect(
      mapper.binanceUsdtSymbolFor(
        coinGeckoId: 'unknown-id',
        coinGeckoSymbol: 'sol',
      ),
      'SOLUSDT',
    );
  });

  test('honors overrides', () {
    final custom = SymbolMapper(overrides: {'obscure-id': 'CUSTOMUSDT'});
    expect(
      custom.binanceUsdtSymbolFor(coinGeckoId: 'obscure-id'),
      'CUSTOMUSDT',
    );
  });
}
