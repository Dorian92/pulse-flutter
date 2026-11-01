/// Application-wide configuration (URLs, timeouts, flags).
class AppConfig {
  /// Creates app configuration.
  const AppConfig({
    this.coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3',
    this.binanceBaseUrl = 'https://api.binance.com',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.apiMaxAttempts = 3,
  });

  /// CoinGecko Demo API root including `/api/v3`.
  final String coinGeckoBaseUrl;

  /// Binance Spot REST root.
  final String binanceBaseUrl;

  /// TCP/connect phase timeout for HTTP requests.
  final Duration connectTimeout;

  /// Total time waiting for response bytes after connect.
  final Duration receiveTimeout;

  /// Maximum attempts for transient failures (including first try).
  final int apiMaxAttempts;
}
