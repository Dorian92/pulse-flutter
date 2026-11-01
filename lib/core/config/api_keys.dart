/// Reads secrets from compile-time `--dart-define` values.
abstract final class ApiKeys {
  /// CoinGecko Demo API key (`COINGECKO_DEMO_API_KEY`).
  static String get coinGeckoDemoApiKey =>
      const String.fromEnvironment('COINGECKO_DEMO_API_KEY');
}
