/// Maps CoinGecko coin ids to Binance USDT spot symbols for live data.
class SymbolMapper {
  /// Creates a mapper with optional overrides for tests.
  const SymbolMapper({Map<String, String>? overrides})
    : _overrides = overrides ?? const {};

  final Map<String, String> _overrides;

  static const Map<String, String> _knownIds = {
    'bitcoin': 'BTCUSDT',
    'ethereum': 'ETHUSDT',
    'binancecoin': 'BNBUSDT',
    'solana': 'SOLUSDT',
    'ripple': 'XRPUSDT',
    'cardano': 'ADAUSDT',
    'dogecoin': 'DOGEUSDT',
    'polkadot': 'DOTUSDT',
    'tron': 'TRXUSDT',
    'avalanche-2': 'AVAXUSDT',
    'chainlink': 'LINKUSDT',
    'litecoin': 'LTCUSDT',
  };

  /// Returns a Binance *USDT symbol (e.g. `BTCUSDT`) or null when no pair is known.
  ///
  /// Only [_knownIds] and [overrides] are consulted until step 5+ builds a map
  /// from Binance `exchangeInfo` (unknown ids show the “no live feed” badge).
  String? binanceUsdtSymbolFor({required String coinGeckoId}) {
    final override = _overrides[coinGeckoId];
    if (override != null) {
      return override;
    }
    return _knownIds[coinGeckoId];
  }
}
