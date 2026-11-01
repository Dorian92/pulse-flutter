# Plan — Design system (roadmap step 2)

## Goals

- Encode the owner-approved dark-first visual direction (with a matching light theme) as **theme tokens** and **reusable presentational widgets**.
- Give feature PRs (markets, coin detail, watchlist) a consistent look: EUR formatting, trend-colored sparklines, filled gain/loss pills, violet accent for selection—not for market direction.
- Provide a **debug-only Design gallery** to review every component state without wiring API data.

## Scope

### Theme (`lib/core/theme/`)

- Finalize `PulseColors` (background/surface semantics via `ColorScheme`, plus gain, loss, warning/offline, accent, live flash, borders).
- Extend `PulseTokens` (spacing scale, radius ~16px cards, durations for motion, elevation if needed).
- Add `PulseTypography` helpers or `TextTheme` extensions with **tabular figures** on price/stat styles.
- Wire dark (`#0B0E14` / `#131722`) and light counterparts into Material 3 `ThemeData`; no hardcoded colors in widgets.

### Widgets (`lib/core/widgets/`)

Presentational only (no bloc, repository, or HTTP):

| Widget | Purpose |
|--------|---------|
| `CoinListTile` | Icon, name, ticker, sparkline, EUR price, change pill, optional live flash, optional no-feed badge |
| `PriceChangePill` | Filled gain/loss percent pill (single style app-wide) |
| `Sparkline` | CustomPainter mini chart, green/red by trend |
| `LiveIndicator` | Green dot + “LIVE” label |
| `OfflineBanner` | Amber banner with cloud-off + stale minutes (l10n) |
| `NoLiveFeedBadge` | Gray badge for symbols without Binance stream |
| `PeriodSelector` | 1D / 1W / 1M / 3M / 1Y pill row |
| `StatsGrid` / `StatTile` | Two-column stats with dividers |
| `FilterChipsRow` | All / Gainers / Losers / Watchlist |
| `MarketSummaryCard` | Global cap + change summary |
| `ShimmerSkeleton` | List tile and detail placeholders |

### Formatting (`lib/core/formatting/`)

- EUR currency, signed percent, compact market cap (T/B/M) with `intl`, supporting **en** and **sr_Latn**.

### Debug gallery (`lib/debug/ui/design_gallery_page.dart`)

- Route registered only when `kDebugMode`; entry link on Settings.
- Shows all components in representative states; theme mode toggle.

### Localization

- All new user-visible strings in `lang/app_en.arb`, mirrored in `app_sr_Latn.arb` and `app_sr.arb` (sync per step 1).

## File layout

```text
lib/core/theme/
  app_colors.dart      # PulseColors, PulseTokens (+ extensions)
  app_theme.dart       # ThemeData light/dark
  pulse_text_styles.dart

lib/core/formatting/
  pulse_formatters.dart

lib/core/widgets/
  coin_list_tile.dart
  price_change_pill.dart
  sparkline.dart
  live_indicator.dart
  offline_banner.dart
  no_live_feed_badge.dart
  period_selector.dart
  stats_grid.dart
  filter_chips_row.dart
  market_summary_card.dart
  shimmer_skeleton.dart

lib/debug/ui/
  design_gallery_page.dart

docs/
  design.md
  design/README.md
  plans/design-system.md   # this file

test/core/formatting/
  pulse_formatters_test.dart
test/core/widgets/
  *_test.dart
```

## Test plan

- **Unit**: formatters (EUR, percent, compact cap) for en and sr_Latn locales.
- **Widget**: each component—default, gain/loss, offline badge, live flash, selected chips, empty stat grid cell where applicable.
- **Golden**: optional for `PriceChangePill` and `Sparkline` in dark/light; skipped in CI unless a bundled test font is added (document in test file)—avoid flaky CI.

## Out of scope (this PR)

- Interactive **coin detail chart** (crosshair, gradient fill, y-axis)—roadmap step 5 (Coin detail with charts).
- Markets/watchlist **bloc wiring** and API data.
- Settings persistence for theme/locale (step 6).
- New pub dependencies (use `intl` already in pubspec; sparkline is CustomPainter).
- Bundling Inter font files (Roboto + tabular figures stand in; see `docs/design.md`).

## Dependencies

No new packages. `intl` for formatting; Flutter SDK for theme and painting.

## Acceptance (roadmap)

- CI green: format, analyze, test, generated l10n check, debug APK.
- Design gallery reachable in debug from Settings.
- Feature pages remain placeholders; they may adopt widgets in later steps.
