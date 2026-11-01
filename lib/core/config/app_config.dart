/// Application-wide configuration (URLs, timeouts, flags).
class AppConfig {
  /// Creates app configuration.
  const AppConfig({
    this.coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3',
    this.binanceBaseUrl = 'https://api.binance.com',
    this.binanceWebSocketUrl = 'wss://stream.binance.com:9443/ws',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.apiMaxAttempts = 3,
    this.realtimeTickThrottle = const Duration(seconds: 1),
    this.realtimeSubscribeDebounce = const Duration(milliseconds: 200),
    this.realtimeBackgroundDisconnectDelay = const Duration(seconds: 30),
    this.realtimeStaleAfter = const Duration(seconds: 45),
    this.realtimeBackoffCap = const Duration(seconds: 60),
    this.realtimeStableResetBackoff = const Duration(seconds: 30),
    this.disableRealtimeLifecycleTeardown = false,
  });

  /// CoinGecko Demo API root including `/api/v3`.
  final String coinGeckoBaseUrl;

  /// Binance Spot REST root.
  final String binanceBaseUrl;

  /// Binance combined WebSocket entry (dynamic SUBSCRIBE).
  final String binanceWebSocketUrl;

  /// Minimum interval between tick broadcasts per symbol.
  final Duration realtimeTickThrottle;

  /// Debounce before sending SUBSCRIBE/UNSUBSCRIBE batches.
  final Duration realtimeSubscribeDebounce;

  /// Delay after background before closing the socket.
  final Duration realtimeBackgroundDisconnectDelay;

  /// Force reconnect when no WS traffic within this window.
  final Duration realtimeStaleAfter;

  /// Maximum reconnect backoff delay.
  final Duration realtimeBackoffCap;

  /// Stable connection duration before backoff counter resets.
  final Duration realtimeStableResetBackoff;

  /// When true, skips background socket teardown (tests).
  final bool disableRealtimeLifecycleTeardown;

  /// Timeout for opening the TCP connection ([HttpClient.connectionTimeout]
  /// on the shared [http.Client] from [createPulseHttpClient]).
  final Duration connectTimeout;

  /// Maximum time to receive the full HTTP response after connect ([ApiClient]
  /// applies this to each GET future).
  final Duration receiveTimeout;

  /// Maximum attempts for transient failures (including first try).
  final int apiMaxAttempts;
}
