# Plan — Core layer (roadmap step 3)

## Goals

- Establish shared **error**, **network**, **cache**, and **composition** primitives so feature PRs (markets, detail, realtime) never talk to `http` or Hive directly.
- Return **`Result<T>`** with explicit staleness for offline/cache-first UX aligned with [caching.md](../caching.md).
- Bootstrap **Hive** and **get_it** once at app start; tests reset and override registrations.

## Scope

### Error (`lib/core/error/`)

| Type | Responsibility |
|------|----------------|
| `Result<T>` | Sealed `Success(value, {isStale})` / `Failure(error)` |
| `AppFailure` | Sealed hierarchy with l10n mapping extension |

**`AppFailure` variants**

| Class | When |
|-------|------|
| `NetworkFailure` | No connectivity, DNS, socket errors (`offline`) |
| `TimeoutFailure` | Request exceeded connect/receive timeout |
| `RateLimitFailure` | HTTP **429**; optional `retryAfter` from `Retry-After` header |
| `ServerFailure` | HTTP **5xx** or **418** (Binance IP ban) |
| `ParsingFailure` | Non-JSON body or decoder threw |
| `NotFoundFailure` | HTTP **404** |
| `CacheFailure` | Hive read/write/envelope errors (recoverable) |
| `UnknownFailure` | Unmapped status or unexpected error |

**Public API (signatures)**

```dart
sealed class Result<T> {
  const Result();
  R when<R>({
    required R Function(T value, bool isStale) success,
    required R Function(AppFailure error) failure,
  });
}

final class Success<T> extends Result<T> {
  const Success(this.value, {this.isStale = false});
  final T value;
  final bool isStale;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

sealed class AppFailure {
  const AppFailure();
}

extension AppFailureLocalization on AppFailure {
  String message(AppLocalizations l10n);
}
```

### Network (`lib/core/network/`)

| Type | Responsibility |
|------|----------------|
| `ApiClient` | GET JSON for CoinGecko + Binance base URLs from `AppConfig` |
| `ApiException` | Internal throwable carrying `AppFailure` (mapped at client boundary) |

**`ApiClient` public API**

```dart
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required AppConfig config,
    required Clock clock,
    void Function(String message)? log,
  });

  Future<Result<T>> getJson<T>({
    required ApiBase base,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required T Function(Object? json) decode,
    int maxAttempts = 3,
  });

  Future<Result<T>> getCoinGeckoJson<T>({ ... }); // adds demo API key header
  Future<Result<T>> getBinanceJson<T>({ ... });
}

enum ApiBase { coinGecko, binance }
```

**Behaviour**

- Connect timeout **15 s** on `HttpClient.connectionTimeout` ([createPulseHttpClient]); receive timeout **30 s** on each GET future in `ApiClient`.
- Decode UTF-8 body as JSON; `ParsingFailure` on invalid JSON or decoder throws.
- Map status codes → `AppFailure` (see table below).
- **Retry:** up to 3 attempts with exponential backoff (500 ms × 2^n) on timeout, socket errors, **502/503/504**, and **429** when `Retry-After` is absent or ≤ **10 s**; larger `Retry-After` fails fast without sleeping.
- **Debug logging:** injectable logger defaulting to `dart:developer` `log` (no Flutter imports).

### Config (`lib/core/config/`)

```dart
class AppConfig {
  const AppConfig({
    this.coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3',
    this.binanceBaseUrl = 'https://api.binance.com',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });
}

abstract final class ApiKeys {
  static String get coinGeckoDemoApiKey =>
      const String.fromEnvironment('COINGECKO_DEMO_API_KEY');
}
```

### Storage (`lib/core/storage/`)

| Type | Responsibility |
|------|----------------|
| `HiveBoxes` | `Hive.initFlutter()` / test path init; open `pulse_cache` box |
| `CacheEnvelope` | `schemaVersion`, `fetchedAt`, `ttlSeconds`, `payload` (JSON map) |
| `CacheStore` | TTL read/write, corrupt entry drop |
| `fetchCacheFirst` | Cache-first helper returning `Success(isStale: true)` when offline or remote fails but stale entry exists |

**`CacheStore` public API**

```dart
class CacheStore {
  CacheStore({required Box<String> cacheBox, required Clock clock});

  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> payload,
    required Duration ttl,
    required int schemaVersion,
  });

  Future<Map<String, dynamic>?> readFresh({
    required String key,
    required int schemaVersion,
  });

  Future<Map<String, dynamic>?> readStale({
    required String key,
    required int schemaVersion,
  });

  Future<void> delete(String key);
  Future<void> clear();
}

Future<Result<T>> fetchCacheFirst<T>({
  required CacheStore cache,
  required ConnectivityService connectivity,
  required String cacheKey,
  required Duration ttl,
  required int schemaVersion,
  required Future<Result<T>> Function() fetchRemote,
  required T Function(Map<String, dynamic> json) decode,
  required Map<String, dynamic> Function(T value) encode,
});
```

**Envelope JSON shape**

```json
{
  "schemaVersion": 1,
  "fetchedAt": "2026-11-01T12:00:00.000Z",
  "ttlSeconds": 600,
  "payload": { }
}
```

### Connectivity (`lib/core/connectivity/`)

```dart
abstract class ConnectivityService {
  Future<bool> get isOnline;
}

class ConnectivityPlusService implements ConnectivityService { ... }
```

Used by `fetchCacheFirst` for explicit offline stale UX (`connectivity_plus`).

### Time (`lib/core/time/`)

```dart
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock { ... }
```

### Realtime stub (`lib/core/realtime/`)

```dart
class SymbolMapper {
  const SymbolMapper({Map<String, String>? overrides});

  /// Returns Binance *USDT symbol (e.g. `BTCUSDT`) or null when no live pair.
  String? binanceUsdtSymbolFor({required String coinGeckoId});
}
```

Static map for common IDs (BTC, ETH, …) plus test [overrides]; returns `null` when unknown (UI shows “no live feed”). Step 4+ will populate from Binance `exchangeInfo`.

### DI (`lib/core/di/injection.dart`)

```dart
final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  AppConfig? appConfig,
  http.Client? httpClient,
  ConnectivityService? connectivityService,
  Clock? clock,
  CacheStore? cacheStore,
}) async;

Future<void> resetDependencies();
```

Registers: `AppConfig`, `Clock`, `http.Client`, `ApiClient`, `ConnectivityService`, `CacheStore`, `SymbolMapper`. Tests call `resetDependencies()` then `configureDependencies(...)` with fakes.

## HTTP status → `AppFailure` mapping

| Condition | `AppFailure` |
|-----------|----------------|
| No network / `SocketException` | `NetworkFailure.offline()` |
| `TimeoutException` / timeout | `TimeoutFailure` |
| HTTP 429 | `RateLimitFailure(retryAfter: …)` |
| HTTP 404 | `NotFoundFailure` |
| HTTP 401 / 403 (CoinGecko key) | `ServerFailure` (message via l10n server) |
| HTTP 418 | `ServerFailure` (Binance ban) |
| HTTP 5xx | `ServerFailure` |
| Invalid JSON / decode error | `ParsingFailure` |
| Other 4xx | `UnknownFailure` |
| Hive / envelope errors | `CacheFailure` |

## Cache keys & TTL (reference for step 4+)

| Key pattern | TTL | Step |
|-------------|-----|------|
| `markets:{vsCurrency}` | 10 min | 4 |
| `coin:{id}:{locale}` | 24 h | 6 |
| `chart:{id}:{range}:{vsCurrency}` | 5 min – 24 h | 6 |
| `prices:snapshot` | none (timestamped) | later |

Step 3 implements **store + helper only**; no feature keys written yet.

## File layout

```text
lib/core/
  config/app_config.dart
  config/api_keys.dart
  connectivity/connectivity_service.dart
  di/injection.dart
  error/app_failure.dart
  error/result.dart
  network/api_client.dart
  network/api_exception.dart
  realtime/symbol_mapper.dart
  storage/cache_store.dart
  storage/cache_first.dart
  storage/hive_boxes.dart
  time/clock.dart

test/core/
  error/result_app_failure_test.dart
  network/api_client_test.dart
  storage/cache_store_test.dart
  storage/cache_first_test.dart
  realtime/symbol_mapper_test.dart
  di/injection_test.dart
```

## Test plan

| File | Cases |
|------|--------|
| `result_app_failure_test.dart` | Success/Failure when; failure → l10n keys |
| `api_client_test.dart` | 200 JSON; 404; 429 + Retry-After; 500; timeout; bad JSON; retry count (mock `http.Client`) |
| `cache_store_test.dart` | fresh/stale/expired via `FakeClock`; corrupt JSON removed; schema mismatch removed |
| `cache_first_test.dart` | fresh hit skips network; offline stale; remote fail + stale; remote fail no cache → Failure |
| `symbol_mapper_test.dart` | map hit; symbol fallback; null |
| `injection_test.dart` | `configureDependencies` + resolve smoke; reset + override |

Hive tests use temp directory (`Directory.systemTemp` + unique path).

## Dependencies added

| Package | Justification |
|---------|----------------|
| `get_it` | Composition root only ([architecture.md](../architecture.md)) |
| `http` | CoinGecko + Binance REST |
| `hive` / `hive_flutter` | TTL cache envelopes ([caching.md](../caching.md)) |
| `connectivity_plus` | Explicit offline detection for cache-first helper |
| `equatable` | Value equality for `AppFailure` variants in tests |
| `mocktail` (dev) | Mockito-free HTTP/connectivity mocks |

## Out of scope (step 3)

- Feature repositories, markets bloc, real endpoints beyond ApiClient unit tests.
- `PriceStreamService`, WebSocket, `preferences_store` / watchlist persistence.
- CoinGecko `/coins/list` driven symbol map (step 4+).
- `json_serializable` DTOs (step 4).

## Doc updates in this PR

- This plan file.
- [architecture.md](../architecture.md) — `Success.isStale`, core file references.
- [caching.md](../caching.md) — envelope field names aligned with implementation.
- [api.md](../api.md) — rate limit re-verification note (Nov 2026).
- [roadmap.md](../roadmap.md) — step 3 acceptance tests list expanded.
