/// Maps CoinGecko coin ids to Binance USDT spot symbols for live data.
class SymbolMapper {
  /// Creates a mapper with optional overrides for tests.
  const SymbolMapper({Map<String, String>? overrides})
    : _overrides = overrides ?? const {};

  final Map<String, String> _overrides;

  static const Map<String, String> _knownIds = {
    'bitcoin': 'BTCUSDT',
    'ethereum': 'ETHUSDT',
    'tether': 'USDTUSDT',
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
  /// Uses [_knownIds], then [overrides], then `{coinGeckoSymbol}USDT` when
  /// [coinGeckoSymbol] is provided.
  String? binanceUsdtSymbolFor({
    required String coinGeckoId,
    String? coinGeckoSymbol,
  }) {
    final override = _overrides[coinGeckoId];
    if (override != null) {
      return override;
    }
    final known = _knownIds[coinGeckoId];
    if (known != null) {
      return known;
    }
    final symbol = coinGeckoSymbol?.trim();
    if (symbol == null || symbol.isEmpty) {
      return null;
    }
    return '${symbol.toUpperCase()}USDT';
  }
}
