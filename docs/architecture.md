# Architecture

Pulse uses **feature-first** modules with a thin **shell** and a shared **core**. UI never calls HTTP or WebSocket APIs directly; data flows in one direction.

## Principles

1. **Feature-first folders** — each feature owns models, repository (interface + impl + data sources), bloc/cubit, and UI.
2. **Constructor injection** — dependencies are passed into constructors; `get_it` registers types only in `core/di/`.
3. **Repository interfaces** — Blocs depend on abstractions; implementations compose remote and local data sources.
4. **Sealed results** — domain and repository layers return `Result<T>` with `AppFailure` instead of throwing for expected errors.
5. **Strict analysis** — `analysis_options.yaml` treats warnings as errors where practical; no ignored lints without a comment.

## Folder tree

```text
lib/
├── main.dart                          # bootstrap, runApp
├── app.dart                           # MaterialApp.router, theme, l10n
├── core/
│   ├── config/
│   │   ├── app_config.dart            # env, base URLs, feature flags
│   │   └── api_keys.dart              # dart-define readers (CoinGecko)
│   ├── di/
│   │   └── injection.dart             # get_it registration (ONLY place)
│   ├── error/
│   │   ├── app_failure.dart           # sealed failure types
│   │   └── result.dart                # sealed Result<T>
│   ├── connectivity/
│   │   ├── connectivity_service.dart
│   │   └── connectivity_plus_service.dart
│   ├── network/
│   │   ├── api_client.dart            # http wrapper, timeouts, decode
│   │   └── api_exception.dart
│   ├── realtime/
│   │   ├── price_stream_service.dart  # abstract + Binance impl (see realtime.md)
│   │   ├── price_tick.dart
│   │   ├── realtime_status.dart
│   │   ├── realtime_subscription_coordinator.dart
│   │   ├── symbol_mapper.dart         # CoinGecko id ↔ Binance symbol
│   │   └── symbol_mapper_loader.dart  # exchangeInfo bootstrap (cached)
│   ├── storage/
│   │   ├── cache_store.dart           # TTL read/write, corrupt entry drop
│   │   ├── preferences_store.dart     # settings, watchlist order
│   │   └── hive_boxes.dart            # box names, adapters registration
│   ├── router/
│   │   └── app_router.dart            # go_router routes + shell
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart            # semantic tokens only
│   └── widgets/
│       ├── coin_list_tile.dart
│       ├── offline_banner.dart
│       └── shimmer_skeleton.dart
├── shell/
│   └── ui/
│       └── main_shell.dart            # bottom nav / navigation rail
├── markets/
│   ├── models/
│   │   ├── market_coin.dart
│   │   └── markets_sort.dart
│   ├── repository/
│   │   ├── markets_repository.dart    # abstract
│   │   ├── markets_repository_impl.dart
│   │   └── data_sources/
│   │       ├── markets_remote_data_source.dart   # CoinGecko + Binance REST
│   │       └── markets_local_data_source.dart    # list cache
│   ├── bloc/
│   │   ├── markets_bloc.dart
│   │   ├── markets_event.dart
│   │   └── markets_state.dart
│   └── ui/
│       └── markets_page.dart
├── coin_detail/
│   ├── models/
│   │   ├── coin_detail.dart
│   │   ├── chart_point.dart
│   │   ├── chart_range_config.dart
│   │   └── price_chart_series.dart
│   ├── repository/
│   │   ├── coin_detail_repository.dart
│   │   ├── coin_detail_repository_impl.dart
│   │   └── data_sources/
│   │       ├── coin_detail_remote_data_source.dart
│   │       └── coin_detail_local_data_source.dart
│   ├── bloc/
│   │   ├── coin_detail_bloc.dart
│   │   ├── coin_detail_event.dart
│   │   └── coin_detail_state.dart
│   └── ui/
│       ├── coin_detail_page.dart
│       └── widgets/
│           ├── coin_detail_header.dart
│           └── price_chart.dart
├── watchlist/
│   ├── models/
│   │   └── watchlist_snapshot.dart
│   ├── repository/
│   │   ├── watchlist_repository.dart
│   │   ├── watchlist_repository_impl.dart
│   │   └── data_sources/
│   │       ├── watchlist_local_data_source.dart
│   │       └── watchlist_markets_data_source.dart
│   ├── bloc/
│   │   ├── watchlist_bloc.dart
│   │   ├── watchlist_event.dart
│   │   └── watchlist_state.dart
│   └── ui/
│       └── watchlist_page.dart
└── settings/
    ├── models/
    │   ├── user_preferences.dart
    │   └── display_currency.dart
    ├── repository/
    │   └── settings_repository.dart
    ├── bloc/
    │   ├── settings_cubit.dart
    │   └── settings_state.dart
    └── ui/
        └── settings_page.dart

test/
├── core/
│   └── realtime/
│       └── fake_price_stream_service.dart
├── markets/
│   └── ...
└── ...
```

## Data flow

```mermaid
flowchart TB
    subgraph UI
        Page[Feature Page / Widgets]
    end
    subgraph BlocLayer
        Bloc[Bloc / Cubit]
    end
    subgraph Domain
        Repo[Repository interface]
    end
    subgraph Data
        Remote[Remote data source]
        Local[Local data source]
    end
    subgraph Core
        Api[ApiClient]
        Cache[CacheStore]
        PSS[PriceStreamService]
    end
    Page -->|events| Bloc
    Bloc -->|states| Page
    Bloc --> Repo
    Repo --> Remote
    Repo --> Local
    Remote --> Api
    Local --> Cache
    Bloc -->|subscribe symbols| PSS
    PSS -->|throttled ticks| Bloc
```

**Live prices:** REST (or cache) loads the initial list; Blocs register interest with `PriceStreamService`; ticks merge into existing `Equatable` state (price, 24h change where available from ticker stream).

### REST cache-first and stale fallback

```mermaid
sequenceDiagram
  participant UI
  participant Repo as Repository
  participant Cache as CacheStore
  participant Remote as Remote DS
  UI->>Repo: load / refresh
  Repo->>Cache: readFresh(key)
  alt TTL valid
    Cache-->>Repo: payload
    Repo-->>UI: Success (isStale=false)
  else miss or refresh forced
    Repo->>Remote: fetch
    alt remote OK
      Remote-->>Repo: DTO
      Repo->>Cache: writeJson(ttl)
      Repo-->>UI: Success
    else remote fail
      Repo->>Cache: readStale(key)
      alt stale exists
        Repo-->>UI: Success (isStale=true, refreshError)
      else no cache
        Repo-->>UI: Failure
      end
    end
  end
```

### Live tick merge (Markets / Detail / Watchlist)

```mermaid
flowchart LR
  WS[Binance WS @ticker] --> PSS[PriceStreamService throttle]
  PSS --> Coord[SubscriptionCoordinator union]
  Coord --> Bloc[Feature Bloc]
  Bloc -->|copyWith price| State[Equatable state]
  State --> UI[List / detail header]
  EUR[EURUSDT stream] --> PSS
```

## Key decisions

| Decision | Rationale |
|----------|-----------|
| CoinGecko for list ranking + metadata; Binance for prices, klines, live ticks | CoinGecko aligns with “top by market cap” and rich copy; Binance has low-latency USD/USDT pairs and stable public streams without a key |
| `SymbolMapper` in core | Binance `BTCUSDT` vs CoinGecko `bitcoin` requires a maintained map (from CoinGecko `/coins/list` + exchangeInfo quote assets) |
| Single WebSocket connection | Binance allows many streams per connection but limits control messages; one service avoids duplicate connections and centralises reconnect |
| `bloc_concurrency` (`restartable`, `droppable`) | Search and refresh should cancel stale work; rapid chart range changes should not pile up |
| `go_router` + shell route | Deep links to `/coin/:id`, watchlist and settings as branches |
| `fl_chart` | MIT license, sufficient for line + candle prototypes; no Syncfusion dependency |
| Hive for cache + watchlist blobs | Fast key-value, works offline, simpler than Drift for mostly-document caches (see caching.md) |
| ARB l10n | Flutter standard; Serbian Latin locale `sr_Latn` (see Decisions below) |

## Decisions (owner-approved)

These choices are fixed unless the owner reprioritizes. Update this section when new product decisions land.

| Topic | Decision |
|-------|----------|
| **Application ID** | `com.doriansabo.pulse` (Android applicationId / iOS bundle identifier) |
| **Serbian locale** | `sr_Latn` (Latin script); ARB template `lang/app_sr.arb` with `"@@locale": "sr_Latn"` |
| **Background / WebSocket** | When the app is backgrounded, close the Binance WebSocket after ~30 seconds (see [realtime.md](realtime.md)) |
| **EUR display** | Live ticks remain USDT from Binance; convert to EUR for display using a live **EUR/USDT** rate. Static list fields (market cap, etc.) use CoinGecko `vs_currency=eur` when EUR is selected |
| **Missing Binance pair** | Coins with no Binance USDT pair still appear; UI shows a **“no live feed”** badge instead of live price updates |
| **Stale cache on network failure** | Repositories return `Success` with `isStale: true` when serving cached data after a failed refresh; UI shows data plus a stale label (see [caching.md](caching.md)) |
| **License** | MIT — Copyright (c) 2026 Dorian Sabo |

## Error handling: `Result` and `AppFailure`

Repositories and services expose **async** methods returning `Result<T>` — not raw DTOs with thrown exceptions for business failures.

```dart
// Conceptual shape (implementation in step 2)
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value, {this.isStale = false});
  final T value;

  /// True when data comes from expired cache (offline or failed refresh).
  final bool isStale;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

sealed class AppFailure {
  const AppFailure();
}

final class NetworkFailure extends AppFailure { /* timeout, offline */ }
final class ServerFailure extends AppFailure { /* 5xx, parse errors */ }
final class RateLimitFailure extends AppFailure { /* 429, retryAfter */ }
final class CacheFailure extends AppFailure { /* read/write; recoverable */ }
final class NotFoundFailure extends AppFailure { /* unknown coin / symbol */ }
final class RealtimeFailure extends AppFailure { /* stream disconnected */ }
```

**UI mapping:** Blocs map `AppFailure` to user-visible messages via l10n keys (`errorNetwork`, `errorRateLimit`, …). Unexpected exceptions are logged and collapsed to a generic `errorUnknown`.

**Remote data sources** may throw on programmer errors; **repository impl** catches I/O and parsing issues and returns `Failure`.

## Cross-cutting concerns

| Concern | Owner |
|---------|--------|
| Auth | None (public APIs only) |
| Logging | `dart:developer` `log` in debug; no PII |
| Currency display | Settings repository provides `vsCurrency`; fiat conversion for display uses CoinGecko prices where needed; live ticks stay in USDT from Binance |
| Testing | Fake repositories + `FakePriceStreamService`; golden tests optional for markets list |

## Testing strategy

Pulse keeps network out of the default test path. Production code uses constructor injection; tests swap fakes at the composition root or pass blocs into pages.

| Layer | Location | Notes |
|-------|----------|--------|
| Unit | `test/core/**` | `Result` / `AppFailure`, `ApiClient` retries, `CacheStore` TTL, `SymbolMapper` |
| Realtime | `test/core/realtime/**` | `FakePriceStreamService`, fake WebSocket channel, reconnect/backoff with `fake_async` |
| Repository | `test/**/repository/**` | Mock remote + real or in-memory Hive cache |
| Bloc | `test/**/bloc/**` | `bloc_test` happy path + failure |
| Widget | `test/**/ui/**` | Mock blocs or `initPulseTestDependencies()` |
| Integration-style (CI) | `test/pulse_happy_path_test.dart` | `PulseApp` + test DI; shared flow in `test/helpers/pulse_happy_path_flow.dart` |
| Device integration (local) | `integration_test/app_test.dart` | Same flow on emulator/device; **not** in CI |
| Visual fixtures | `tool/screenshot_capture_test.dart` | Tagged `screenshots`; writes PNGs for README / demo |

**Running:** `flutter test --coverage` (CI). Live CoinGecko/Binance are optional manual checks with `--dart-define=COINGECKO_DEMO_API_KEY=...` — not required for CI.

**Offline / stale UX:** When `ConnectivityService` reports offline or remote refresh fails, repositories prefer `readStale` and return `Success` with `isStale: true` (and optional `refreshError`). UI shows `OfflineBanner` / stale copy from l10n while still rendering cached rows.

## Dependency injection

All concrete types are registered in `lib/core/di/injection.dart` via `get_it`. Features receive interfaces through constructors; only `main` and tests call `configureDependencies` / `resetDependencies`. Tests override repositories, `PriceStreamService`, and `ConnectivityService` without touching widgets.

## Related docs

- [Real-time design](realtime.md)
- [Caching](caching.md)
- [HTTP / WS APIs](api.md)
- [Delivery roadmap](roadmap.md)

## Proposed packages

| Package | Role |
|---------|------|
| `flutter_bloc` | Feature state management with explicit events/states |
| `bloc_concurrency` | `restartable` / `droppable` transformers for search and refresh |
| `go_router` | Declarative routes, deep links, shell navigation |
| `get_it` | Service locator limited to composition root |
| `http` | CoinGecko + Binance REST with minimal surface |
| `web_socket_channel` | Binance combined stream + ping/pong handling |
| `json_annotation` / `json_serializable` / `build_runner` | DTO parsing with generated codecs |
| `equatable` | Value equality for states and cache models |
| `fl_chart` | Line and candle charts on coin detail |
| `hive` / `hive_flutter` | TTL cache envelopes, watchlist, settings persistence |
| `intl` | Formatting fiat amounts and dates (with gen-l10n) |
| `mocktail` | Mockito-free mocks for repositories and HTTP |
| `bloc_test` | Declarative Bloc/Cubit behaviour tests |
| `flutter_test` | Widget and integration tests |
| `connectivity_plus` | Offline detection for cache-first refresh (`ConnectivityPlusService`) |
| `package_info_plus` (optional) | About screen / debug overlay only |
