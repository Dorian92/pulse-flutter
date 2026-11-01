# Plan — Coin detail (roadmap step 6)

## Goals

- Replace the `/coin/:id` placeholder with a **cache-first** detail screen: CoinGecko metadata, **interactive EUR price chart** (1D / 1W / 1M / 3M / 1Y), live price via shared **`PriceStreamService`**, stats grid, About section, loading/error/offline UX per [design.md](../design.md) and [caching.md](../caching.md).
- Register a **`coin_detail:<coinId>`** subscription token with **`RealtimeSubscriptionCoordinator`** while the page is open; remove on bloc close.
- **EUR consistently:** static fields from CoinGecko `vs_currency=eur`; Binance kline closes (USDT) multiplied by **`EURUSDT`** mid at fetch time; live ticks use existing **`PriceTick.lastPriceEur`**.

## Scope alignment

| Source | Step 6 |
|--------|--------|
| [roadmap.md](../roadmap.md) | `coin_detail/` module, CG detail, Binance klines + CG fallback chart, `fl_chart`, live price, tests |
| Owner task | Ranges include **3M**; metadata TTL 24h; chart TTLs from caching.md (+ 3M row); watchlist star (stub persistence OK); shimmer, retry, stale banner |
| Out of scope | Full watchlist persistence/reorder (step 7), settings currency toggle, candle/OHLC chart, deep links beyond existing route, README screenshots section |

## Chart library

**`fl_chart`** (MIT, already in [architecture.md](../architecture.md)): line chart with gradient fill, touch crosshair/tooltip, and axis labels without maintaining a custom painter for drag hit-testing. Single new dependency justified by interactive tooltip + range switching.

## File layout

```text
lib/coin_detail/
├── models/
│   ├── coin_detail.dart           # metadata + stats fields
│   ├── chart_point.dart
│   └── price_chart_series.dart    # points, range, source enum
├── repository/
│   ├── coin_detail_repository.dart
│   ├── coin_detail_repository_impl.dart
│   └── data_sources/
│       ├── coin_detail_remote_data_source.dart
│       └── coin_detail_local_data_source.dart
├── watchlist/
│   └── watchlist_toggle.dart      # abstract + in-memory stub (step 7)
├── bloc/
│   ├── coin_detail_bloc.dart
│   ├── coin_detail_event.dart
│   └── coin_detail_state.dart
└── ui/
    ├── coin_detail_page.dart
    └── widgets/
        ├── coin_detail_header.dart
        ├── price_chart.dart       # fl_chart wrapper
        └── coin_detail_about.dart

test/coin_detail/
├── fixtures/
│   ├── coingecko_coin_bitcoin.json
│   ├── coingecko_market_chart_7d.json
│   └── binance_klines_btc_1h.json
├── models/coin_detail_parsing_test.dart
├── repository/coin_detail_repository_impl_test.dart
├── bloc/coin_detail_bloc_test.dart
└── ui/coin_detail_page_test.dart
```

## Data sources per range

| UI range | Primary (Binance pair exists) | Fallback (no pair) |
|----------|------------------------------|---------------------|
| 1D | `GET /klines` `interval=5m`, `limit=288` | CG `market_chart?vs_currency=eur&days=1` |
| 1W | `interval=1h`, `limit=168` | `days=7` |
| 1M | `interval=4h`, `limit=180` | `days=30` |
| 3M | `interval=1d`, `limit=90` | `days=90` |
| 1Y | `interval=1d`, `limit=365` | `days=365` |

**EUR conversion (Binance path):** after klines fetch, `GET /ticker/price?symbol=EURUSDT` → `priceEur = closeUsdt / eurUsdt` per candle (same formula as live USDT→EUR in step 5).

**Metadata:** `GET /coins/{id}?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false` — description from `description.en`, HTML stripped to plain text.

## Cache keys and TTL

| Key | TTL | Payload |
|-----|-----|---------|
| `coin:{id}:meta:eur` | **24 h** | `CoinDetail` JSON (`schemaVersion: 2`) |
| `chart:{id}:{range}:eur` | per range | `PriceChartSeries` JSON (`schemaVersion: 1`) |

| Range key segment | TTL |
|-------------------|-----|
| `1d` | **5 min** |
| `1w` | **15 min** |
| `1m` | **1 h** |
| `3m` | **6 h** (UI period; interpolated between 1M and 1Y — documented here and in [caching.md](../caching.md)) |
| `1y` | **24 h** |

`loadDetail` / `loadChart` use **`fetchCacheFirst`**; retry button calls repository refresh paths (bypass TTL when online).

## Repository API

```dart
abstract class CoinDetailRepository {
  Future<Result<CoinDetail>> loadDetail(String coinId);
  Future<Result<PriceChartSeries>> loadChart({
    required String coinId,
    required ChartPeriod range,
  });
}
```

Impl resolves Binance symbol via **`SymbolMapper`**, chooses primary/fallback in remote, writes envelopes via **`CoinDetailLocalDataSource`**.

## Bloc

**Events:** `CoinDetailStarted(coinId)`, `CoinDetailChartRangeChanged(ChartPeriod)`, `CoinDetailRetryRequested`, internal `CoinDetailPriceTickReceived`, `CoinDetailRealtimeStatusChanged`, `CoinDetailWatchlistToggled`.

**State:** `status` (initial/loading/loaded/failure), `coinId`, `detail`, `chart`, `selectedRange`, `livePriceEur`, `changePercent24h`, `realtimeStatus`, `isStale`, `chartLoading`, `failure`, `isWatchlisted`, `fetchedAt`.

**Concurrency:** `restartable()` on `CoinDetailChartRangeChanged` so rapid period taps cancel in-flight chart loads.

**Live integration:**

- On `CoinDetailStarted`: load detail + default chart (1D); subscribe ticks + status; `coordinator.setSymbols('coin_detail:$coinId', {symbol})` when mapper returns a pair.
- On tick: update `livePriceEur` / `changePercent24h` when `tick.symbol` matches.
- On `close`: cancel subscriptions, `coordinator.removeToken('coin_detail:$coinId')`.

## UI (design.md mockup 2)

- App bar: back, coin icon + name/ticker, watchlist **`IconButton`** (star).
- Hero: large EUR price (`PulseFormatters.formatEurPrice`), **`PriceChangePill`**, **`LiveIndicator`** or **`NoLiveFeedBadge`**.
- **`PriceChart`**: line + gradient (green/red by first vs last point), touch tooltip (price + time).
- **`PeriodSelector`**, **`StatsGrid`** (market cap, 24h volume, high/low, supply, ATH).
- **`CoinDetailAbout`**: muted body text.
- Loading: **`ShimmerSkeleton(detailHeader)`**; chart area shimmer block.
- Error: message + **`marketsRetry`** l10n button.
- Stale: **`OfflineBanner`** from `fetchedAt` when `isStale`.

## Error handling

| Failure | UI |
|---------|-----|
| No cache + offline | Full-screen error + retry |
| Cache + failed refresh | Show data + stale banner |
| Chart load fail with detail loaded | Inline chart error + retry (detail stays) |
| `NotFoundFailure` | Error state (unknown coin id) |

## Watchlist star

**`WatchlistToggle`** interface + **`InMemoryWatchlistToggle`** registered in DI (process-local set). Step 7 replaces impl with persisted repository without UI changes.

## Test plan

| Layer | Cases |
|-------|--------|
| Models | Parse CG detail + market_chart fixtures; HTML strip |
| Repository | Cache hit/miss; TTL per range key; Binance path vs CG fallback when `SymbolMapper` null; stale fallback offline |
| Bloc | Happy load; range change restartable; tick merge; stale flag; coordinator register/remove (mock coordinator); watchlist toggle |
| Widget | Loading shimmer; loaded stats; no-live-feed badge; period switch triggers event; error retry button |

No real network; mock **`ApiClient`**, fake cache, **`FakePriceStreamService`**.

## Docs updates (same PR)

- Add **3M** row to [caching.md](../caching.md) chart TTL table.
- Optional one-line in [api.md](../api.md) detail fusion (already described).

## Deferred

- Serbian description (`description` localization strategy — step 7 l10n).
- Chart source badge in UI (“CoinGecko history”) — optional debug-only.
- Pull-to-refresh on detail (retry button only in v1).

## Chart vs live price

- Historical chart series come from REST/cache only; **live WebSocket ticks update the header price, not the chart line** (optional live point append deferred).
- Chart loads pass **`binanceSymbol` from metadata** so `/coins/{id}` is not re-fetched on every range cache miss.

## Realtime note

- `CoinDetailBloc` listens to the shared **`PriceStreamService.ticks`** broadcast and **ignores ticks** whose symbol does not match the open coin (same global-stream filter pattern as markets).
