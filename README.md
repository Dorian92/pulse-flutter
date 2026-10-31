# Pulse

**Pulse** is a portfolio-grade crypto market tracker built with **Flutter**. It demonstrates feature-first architecture, layered caching, a shared real-time price pipeline, and test-driven delivery—skills Dorian uses as a Senior Flutter engineer. A separate **React Native** twin is planned in another repository; this repo is the Flutter reference implementation.

## Planned features

| Area | Scope |
|------|--------|
| **Markets** | Top ~100 coins: price, 24h change, sparkline; search and sort; live price updates |
| **Coin detail** | Line/candle chart (1D / 1W / 1M / 1Y), stats (market cap, volume, high/low), description and links, add to watchlist |
| **Watchlist** | Saved coins with live prices; swipe to remove with undo; drag to reorder; persisted locally |
| **Settings** | Theme (system / light / dark), language (EN / Serbian Latin), display currency (USD / EUR); persisted |

## Tech stack

- **Flutter** 3.35+ (stable channel), **Dart 3**
- **State:** `flutter_bloc`, `bloc_concurrency` (from step 2 onward)
- **Navigation:** `go_router`
- **DI:** `get_it` (composition root only); constructor injection elsewhere
- **Network:** `http`, `web_socket_channel`
- **Models:** `json_serializable`, `equatable`
- **Charts:** `fl_chart` (see [architecture](docs/architecture.md))
- **Storage:** `hive` + `hive_flutter` (see [caching](docs/caching.md))
- **L10n:** ARB under `lang/` (`app_en.arb`, `app_sr.arb`, `app_sr_Latn.arb`), generated to `lib/l10n/`
- **Tests:** `flutter_test`, `bloc_test`, `mocktail`

## Documentation

| Doc | Contents |
|-----|----------|
| [Architecture](docs/architecture.md) | Folder layout, data flow, `Result` / failures, key decisions |
| [Real-time](docs/realtime.md) | `PriceStreamService` (Binance WebSocket) |
| [Caching](docs/caching.md) | TTLs, offline behaviour, storage |
| [API](docs/api.md) | Binance + CoinGecko endpoints, limits, samples |
| [Roadmap](docs/roadmap.md) | Step-by-step PR plan |
| [AGENTS.md](AGENTS.md) | Conventions for humans and coding agents |

## Data sources

- **[Binance Spot](https://github.com/binance/binance-spot-api-docs)** — public REST + WebSocket market data (no API key for read-only market endpoints)
- **[CoinGecko Demo API](https://docs.coingecko.com/demo/reference/introduction)** — coin metadata, logos, descriptions, market cap; requires a free Demo API key

## Demo & screenshots

<!-- TBD: record after step 7 -->
_GIF and screenshots will be added after the UI milestone (roadmap step 7)._

## Getting started

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (CI pins **3.35.7**).

```bash
flutter pub get
flutter gen-l10n   # also runs via `flutter pub get` when ARBs change
flutter run
```

Run tests and analysis locally (matches CI):

```bash
dart format lib test
flutter analyze
flutter test --coverage
bash tool/check_generated.sh
```

Application ID: **`com.doriansabo.pulse`** (Android/iOS).

### Configuration

| Variable | Purpose |
|----------|---------|
| `COINGECKO_DEMO_API_KEY` | Passed at build/run time (e.g. `--dart-define=COINGECKO_DEMO_API_KEY=...`); required from roadmap step 3; never committed |

Binance market data endpoints used by Pulse do not require a key.

## CI

GitHub Actions (`.github/workflows/ci.yml`) on every pull request and push to `main`:

- `dart format --set-exit-if-changed lib test`
- `flutter analyze` (strict `analysis_options.yaml`)
- `flutter test --coverage` (coverage uploaded as an artifact)
- `tool/check_generated.sh` — committed `gen-l10n` output (and `build_runner` when added)
- `flutter build apk --debug` on Ubuntu

On **push to `main` only**, a macOS job runs `flutter build ios --no-codesign`.

Dependabot watches pub and GitHub Actions weekly (`.github/dependabot.yml`).

## Testing & localisation

- **Tests:** widget smoke (shell tabs, coin detail route); unit and bloc tests added per roadmap step.
- **L10n:** English plus Serbian Latin (`sr_Latn`); ARB files in `lang/`. Flutter requires a base `app_sr.arb` fallback when using `app_sr_Latn.arb`.

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Dorian Sabo.
