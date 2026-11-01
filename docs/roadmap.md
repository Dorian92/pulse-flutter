# Roadmap

Delivery is split into **eight PRs** (one step each). Each PR should stay reviewable, update docs when behaviour changes, and include tests listed under acceptance criteria.

---

## Step 1 — Project setup, lints, CI, theme, router

**Scope**

- `flutter create` with org/package name agreed by owner.
- `analysis_options.yaml`: strict mode (`analyzer: errors`, key lints).
- GitHub Actions: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
- App shell: `MaterialApp.router`, light/dark `ThemeData`, semantic colors in `core/theme/`.
- `go_router` routes: `/`, `/coin/:id`, `/watchlist`, `/settings` (placeholder pages).
- README: replace TBD run instructions.

**Acceptance criteria**

- CI green on empty test.
- Navigate between four placeholder screens.
- No hard-coded colors in feature UI (use theme).

**Tests**

- Widget test: router resolves `/coin/bitcoin` placeholder.

---

## Step 2 — Design system

**Scope**

- Tokenized theme (dark-first + light): colors, typography with tabular figures, spacing, radius, motion.
- Reusable presentational widgets in `core/widgets/` (list tile, sparkline, pills, banners, chips, stats grid, shimmer).
- EUR / percent / compact formatters with en + sr_Latn.
- Debug-only Design gallery screen (Settings entry).
- Docs: `docs/plans/design-system.md`, `docs/design.md`, `docs/design/`.

**Acceptance criteria**

- No hardcoded colors in widgets; components match approved visual direction.
- Design gallery shows all components and theme toggle.
- CI green.

**Tests**

- Widget tests for components (states, trend colors).
- Unit tests for formatters.
- Golden tests optional/skipped if not deterministic on CI.

**Out of scope**

- Interactive coin detail chart (step 6 — coin detail with charts).

---

## Step 3 — Core: ApiClient, Result, failures, storage, DI

**Scope**

- `Result<T>`, sealed `AppFailure`.
- `ApiClient` (timeouts, JSON decode, 429 mapping).
- `CacheStore` + Hive bootstrap (boxes, envelope type).
- `get_it` in `core/di/injection.dart` only.
- `SymbolMapper` stub (manual map for dev until step 4).

**Acceptance criteria**

- Unit tests for `Result`/`AppFailure` mapping from HTTP exceptions.
- Hive initializes in test harness.
- `get_it` composition root resolves `ApiClient`, `CacheStore`, `SymbolMapper`.
- Plan documented in `docs/plans/core-layer.md`.

**Tests**

- `api_client_test.dart`
- `cache_store_test.dart`
- `cache_first_test.dart`, `symbol_mapper_test.dart`, `injection_test.dart`
- `result_app_failure_test.dart`

---

## Step 4 — Markets list via REST with caching

**Scope**

- Feature module `markets/`: models, remote (CoinGecko `/coins/markets` + `/global`), local cache, repository, bloc, UI list.
- Cache-first TTL 10 min; pull-to-refresh bypasses TTL.
- Search (client filter), filter chips (All / Gainers / Losers; watchlist chip hidden until step 7).
- Sparkline from CoinGecko `sparkline_in_7d`; **MarketSummaryCard** from global endpoint.
- “No live feed” badge via `SymbolMapper`; LIVE indicator placeholder (no WebSocket).
- Binance 24hr batch deferred to step 5 (live price fusion).

**Acceptance criteria**

- Shows ~100 coins from network with loading/error/empty states.
- Offline shows cached list + stale banner when applicable.
- CoinGecko key from dart-define; tap row navigates to `/coin/:id`.

**Tests**

- Model JSON fixtures; repository tests with mocked HTTP + fake cache.
- `MarketsBloc` load / refresh / error via `bloc_test`.
- Widget tests for markets screen loading, error, stale banner.

---

## Step 5 — Live prices with `PriceStreamService`

**Scope**

- Implement `PriceStreamService` + `RealtimeSubscriptionCoordinator`.
- Integrate markets + watchlist blocs (watchlist UI may still be stub).
- Throttle ~1s; reconnect with backoff; status stream.
- `FakePriceStreamService` for tests.

**Acceptance criteria**

- Visible rows update price without full list reload.
- Disconnect shows degraded state; no crash on 24h cycle (simulated in test).

**Tests**

- Unit: throttle coalescing, subscribe diff, backoff timer (fake async).
- Bloc: tick merges into existing state.

---

## Step 6 — Coin detail with charts

**Scope**

- `coin_detail/`: CoinGecko detail endpoint, Binance klines per range, chart widget (`fl_chart`).
- Ranges 1D / 1W / 1M / 1Y with caching TTLs from `caching.md`.
- Stats section, description, links; watchlist toggle (persist stub OK if step 7 completes persistence).

**Acceptance criteria**

- Chart loads per range; error retry.
- Live price on detail via shared stream.

**Tests**

- Repository chart range keys and TTL logic.
- Widget test: chart placeholder with mocked data.

---

## Step 7 — Watchlist, settings, l10n

**Scope**

- Watchlist persistence, reorder, swipe remove + undo snackbar.
- Settings: theme mode, locale (EN + Serbian Latin ARB files), display currency USD/EUR.
- Wire preferences into CoinGecko `vs_currency` and theme/locale.
- Generate l10n; no user-facing hard-coded strings in features.

**Acceptance criteria**

- Watchlist survives restart.
- Language and currency change refresh markets appropriately.
- Serbian strings complete for main flows.

**Tests**

- Watchlist repository order mutations.
- Settings cubit persistence mock.
- L10n smoke test (one widget per locale).

---

## Step 8 — Tests polish, README, demo recording

**Scope**

- Coverage gaps closed on repositories and blocs.
- Integration test (optional) behind flag.
- README GIF/screenshots; architecture docs updated if drifted.
- `AGENTS.md` review.

**Acceptance criteria**

- CI green; `flutter test` runtime acceptable.
- README demo media present.
- No open P0 bugs on happy path.

**Tests**

- Full suite green; document how to run with/without live network.

---

## After v1 (out of scope for steps 1–8)

- React Native twin repository.
- CoinGecko Pro / Binance signed endpoints (not needed for Pulse).
- Push notifications, accounts, portfolios.
