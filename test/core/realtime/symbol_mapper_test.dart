import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';

void main() {
  const mapper = SymbolMapper();

  test('maps known CoinGecko ids', () {
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'bitcoin'), 'BTCUSDT');
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'ethereum'), 'ETHUSDT');
  });

  test('returns null when id is not in the static map', () {
    expect(mapper.binanceUsdtSymbolFor(coinGeckoId: 'obscure-id'), isNull);
  });

  test('honors overrides', () {
    const custom = SymbolMapper(overrides: {'obscure-id': 'CUSTOMUSDT'});
    expect(
      custom.binanceUsdtSymbolFor(coinGeckoId: 'obscure-id'),
      'CUSTOMUSDT',
    );
  });
}
