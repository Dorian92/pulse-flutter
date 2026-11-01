/// Fiat currency used for CoinGecko quotes and UI formatting.
enum DisplayCurrency {
  /// Euro display and CoinGecko `vs_currency=eur`.
  eur,

  /// US dollar display; live ticks use Binance USDT price.
  usd;

  /// CoinGecko `vs_currency` query value.
  String get coingeckoCode => switch (this) {
    DisplayCurrency.eur => 'eur',
    DisplayCurrency.usd => 'usd',
  };

  /// Parses persisted string; defaults to [eur] when unknown.
  static DisplayCurrency fromPersisted(String? raw) {
    return switch (raw) {
      'usd' => DisplayCurrency.usd,
      'eur' => DisplayCurrency.eur,
      _ => DisplayCurrency.eur,
    };
  }

  /// Value stored in Hive JSON.
  String get persistedValue => name;
}
