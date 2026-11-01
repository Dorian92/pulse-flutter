/// Maps CoinGecko coin ids to Binance USDT spot symbols for live data.
class SymbolMapper {
  /// Creates a mapper with optional overrides for tests.
  SymbolMapper({Map<String, String>? overrides})
    : _overrides = overrides ?? const {};

  final Map<String, String> _overrides;
  final Map<String, String> _exchangeByBaseAsset = {};

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

  /// Merges base-asset → Binance symbol entries from cached `exchangeInfo`.
  void applyExchangeBaseAssets(Map<String, String> baseAssetToSymbol) {
    _exchangeByBaseAsset.addAll(baseAssetToSymbol);
  }

  /// Returns a Binance *USDT symbol (e.g. `BTCUSDT`) or null when no pair is known.
  ///
  /// Resolution order: [overrides], static [_knownIds], then `exchangeInfo` match
  /// on uppercase [coinGeckoSymbol] base asset.
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
    if (coinGeckoSymbol == null || coinGeckoSymbol.isEmpty) {
      return null;
    }
    final base = coinGeckoSymbol.toUpperCase();
    return _exchangeByBaseAsset[base];
  }
}
