# Pulse

**Pulse** is a portfolio-grade crypto market tracker built with **Flutter**. It demonstrates feature-first architecture, layered caching, a shared real-time price pipeline, and test-driven delivery—skills Dorian uses as a Senior Flutter engineer. A separate **React Native** twin is planned in another repository; this repo is the Flutter reference implementation.

## Planned features

| Area | Scope |
|------|--------|
| **Markets** | Top ~100 coins: price, 24h change, sparkline; search and sort; live price updates |
| **Coin detail** | Line/candle chart (1D / 1W / 1M / 1Y), stats (market cap, volume, high/low), description and links, add to watchlist |
| **Watchlist** | Saved coins with live prices; swipe to remove with undo; drag to reorder; persisted locally |
| **Settings** | Theme (system / light / dark), language (EN / Serbian Latin), display currency (USD / EUR); persisted |

## Tech stack (planned)

- **Flutter** (stable channel), **Dart 3**
- **State:** `flutter_bloc`, `bloc_concurrency`
- **Navigation:** `go_router`
- **DI:** `get_it` (composition root only); constructor injection elsewhere
- **Network:** `http`, `web_socket_channel`
- **Models:** `json_serializable`, `equatable`
- **Charts:** `fl_chart` (see [architecture](docs/architecture.md))
- **Storage:** `hive` + `hive_flutter` (see [caching](docs/caching.md))
- **L10n:** ARB (`flutter gen-l10n`), EN + Serbian (Latin)
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

<!-- TBD: after step 1 -->
```text
# Instructions pending project scaffold (roadmap step 1).
# Expected shape:
#   flutter pub get
#   dart run build_runner build --delete-conflicting-outputs
#   flutter run
```

### Configuration (planned)

| Variable | Purpose |
|----------|---------|
| `COINGECKO_DEMO_API_KEY` | Passed at build/run time (e.g. `--dart-define`); never committed |

Binance market data endpoints used by Pulse do not require a key.

## CI (planned)

GitHub Actions: `dart format --set-exit-if-changed`, `flutter analyze` (strict), `flutter test` — see [roadmap](docs/roadmap.md).

### Testing & localisation (planned)

- **Tests:** unit (repositories, `PriceStreamService`), `bloc_test` for features, fakes for network and WebSocket; no live Binance in default CI.
- **L10n:** ARB files under `lib/l10n/` (`app_en.arb`, `app_sr.arb` or `sr_Latn`), `flutter gen-l10n`, locale from settings cubit.

## License

TBD (recommend MIT for portfolio use).
