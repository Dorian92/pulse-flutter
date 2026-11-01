# Pulse design system reference

Dark-first crypto UI aligned with three approved mockups (Markets, Coin detail, Watchlist). Tokens drive all colors; widgets must not use raw hex values.

## Brand colors

| Token | Dark | Light | Usage |
|-------|------|-------|--------|
| Background | `#0B0E14` | `#F8FAFC` | Scaffold |
| Surface / card | `#131722` | `#FFFFFF` | Cards, list tiles |
| Border subtle | `#1E2230` | `#E2E8F0` | Card outlines |
| Accent (electric violet) | `#7C5CFF` | `#6D4FE0` | Selected chips, nav indicator, primary actions |
| Gain green | `#16C784` | `#0E9F6E` | Positive change, up sparklines, LIVE dot |
| Loss red | `#EA3943` | `#DC2626` | Negative change, down sparklines |
| Warning amber | `#F59E0B` | `#D97706` | Offline / stale banner |
| Text primary | `#F1F5F9` | `#0F172A` | Titles, prices |
| Text secondary | `#94A3B8` | `#64748B` | Tickers, captions, About body |
| Text muted | `#64748B` | `#94A3B8` | Hints, disabled |
| No live feed | `#475569` | `#94A3B8` | Badge background/text |
| Live flash tint | `#16C784` @ 12% | `#0E9F6E` @ 12% | Brief row highlight on tick |

Access in code: `Theme.of(context).colorScheme`, `context.pulseColors`, `context.pulseTokens`.

## Typography

- **Family**: Inter-like sans; implementation uses platform/Roboto until Inter is bundled (no extra dependency in step 2).
- **Scale** (Material `TextTheme` mapping):
  - Display / screen title: 28–32 sp, w700 — “Markets”, “Watchlist”
  - Title large: 22 sp, w600 — coin name on detail
  - Title medium: 16 sp, w600 — card titles
  - Body: 14 sp, w400 — About, banner subtext
  - Label: 12 sp, w500 — pills, badges, axis labels
- **Numbers**: all price, percent, and stat values use `FontFeature.tabularFigures()` via `PulseTextStyles.price()` / `.percent()` so live updates do not shift layout.

## Spacing & radius

| Token | Value |
|-------|-------|
| `spacingXs` | 4 |
| `spacingSm` | 8 |
| `spacingMd` | 16 |
| `spacingLg` | 24 |
| `spacingXl` | 32 |
| `radiusSm` | 8 |
| `radiusMd` | 12 |
| `radiusLg` | 16 (default card) |
| `listTileHeight` | 72 (markets), 80 (watchlist variant) |

## Elevation & borders

- Cards: elevation 0, 1 px border (`borderSubtle`), radius `radiusLg`.
- No heavy shadows; dark UI reads from surface contrast.

## Motion

| Token | Duration | Use |
|-------|----------|-----|
| `durationFast` | 150 ms | Chip selection |
| `durationMedium` | 300 ms | Live price flash fade |
| `durationSlow` | 450 ms | Shimmer cycle |

## Component catalogue

### CoinListTile

States: default; **live flash** (green tint border/background, animates out); **no live feed** badge; gain vs loss pill; optional larger sparkline (watchlist).

### PriceChangePill

**Filled** pill only app-wide: green background + white text for gain; red for loss. Includes arrow prefix in label. Outlined variant is not used (mockup 3 outline deferred for consistency).

### Sparkline

7-day (or arbitrary) series; stroke/fill colored by **first vs last** point (green up, red down). Never violet.

### LiveIndicator

Small green circle + “LIVE” (l10n).

### OfflineBanner

Full-width amber bar; cloud-off icon; “Offline — showing prices from {n} min ago”.

### NoLiveFeedBadge

Compact gray pill on tile when symbol has no Binance stream.

### PeriodSelector

Horizontal pills: 1D, 1W, 1M, 3M, 1Y; selected = violet fill.

### StatsGrid / StatTile

Two columns, hairline dividers; label muted, value tabular.

### FilterChipsRow

All (default selected), Gainers, Losers, Watchlist.

### MarketSummaryCard

Summary line e.g. global market cap with compact notation and change pill.

### ShimmerSkeleton

Placeholder for list row and detail header/chart block.

## Usage rules

1. **Currency**: display **EUR (€)** in UI components and formatters for this phase (settings currency toggle comes later).
2. **Sparklines**: trend color only (green/red).
3. **Accent violet**: selection, navigation, primary buttons—not P&amp;L.
4. **Percent pills**: one filled style everywhere.
5. **Strings**: ARB only; no literals in widgets.
6. **Theme**: read colors from theme/extensions; never `Color(0x…)` in `lib/` outside `app_colors.dart` / `app_theme.dart`.

## Accessibility

- Gain/loss colors paired with **arrow direction** and sign in text, not color alone.
- Target WCAG AA for body text on background: primary `#F1F5F9` on `#0B0E14` ≈ 15:1; secondary `#94A3B8` on `#0B0E14` ≈ 7:1.
- Touch targets ≥ 48 dp for chips and nav.
- Live flash is decorative; price change also reflected in pill text.

## Approved screens (written spec)

### Mockup 1 — Markets

Large title “Markets”; top-right green LIVE dot and search icon. Filter chips: All (violet fill), Gainers, Losers, Watchlist. Summary card “Global market cap €2.31T +1.8%” with chart icon. Coin rows: round icon, name + ticker, 7d sparkline, right-aligned EUR price, filled percent pill below price; Solana row shows subtle green live flash. Bottom nav: Markets active (violet), Watchlist, Settings.

### Mockup 2 — Coin detail (Bitcoin)

Back, icon + “Bitcoin BTC”, watchlist star. Large EUR price; pill “▲ +2.41% (24h)” and LIVE. Large green line chart with gradient, crosshair tooltip, axes—**implemented in step 5**; this step provides period selector + stats grid + typography/colors only. Stats grid: market cap, 24h volume, high, low, circulating supply, ATH. About section with gray body text.

### Mockup 3 — Watchlist

Title + violet “Edit”. Amber offline banner. Tiles with larger sparkline, outlined-style **replaced by filled pill per consistency rule**; Chainlink shows “No live feed”. Swipe-to-remove UI is feature work (step 6); gallery demonstrates remove affordance hint. Empty hint: “Add assets to track them here.” Bottom nav: Watchlist active.

## Design gallery

Debug builds: **Settings → Design gallery** (`/debug/design-gallery`). Toggle light/dark; scroll sections for each component.
