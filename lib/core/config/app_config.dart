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

  /// Timeout for opening the TCP connection ([HttpClient.connectionTimeout]
  /// on the shared [http.Client] from [createPulseHttpClient]).
  final Duration connectTimeout;

  /// Maximum time to receive the full HTTP response after connect ([ApiClient]
  /// applies this to each GET future).
  final Duration receiveTimeout;

  /// Maximum attempts for transient failures (including first try).
  final int apiMaxAttempts;
}
