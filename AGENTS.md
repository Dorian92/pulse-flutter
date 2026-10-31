# Agent and contributor guide

Instructions for **coding agents** and contributors working on Pulse. Read this before opening a PR.

## Product context

Pulse is a **Flutter** crypto tracker (Binance live + CoinGecko metadata). Documentation lives in `/docs`. Implementation follows the [roadmap](docs/roadmap.md) — **one step per PR**, in order, unless the owner reprioritizes.

## Architecture rules

1. **Feature-first layout** — see [architecture.md](docs/architecture.md). Do not add `services/` or `utils/` dumping grounds; use `core/` for shared code.
2. **One-way data flow** — UI → Bloc/Cubit → Repository → Data sources. No `http` calls from widgets.
3. **Constructor injection** — dependencies via constructors. **`get_it` only in `lib/core/di/injection.dart`.**
4. **Repository interfaces** — Blocs depend on abstractions (`MarketsRepository`, not `MarketsRepositoryImpl`).
5. **Result pattern** — repositories return `Result<T>` with `AppFailure`; do not throw for expected I/O failures.
6. **Realtime** — only `PriceStreamService` opens Binance WebSockets. Features register symbols via the coordinator documented in [realtime.md](docs/realtime.md).

## Code quality

- Run **`dart format .`** before commit.
- **`flutter analyze`** must pass with project strict options (step 1).
- **No hard-coded user strings** — use ARB (`AppLocalizations`).
- **No hard-coded colors** — use `Theme.of(context)` and `core/theme/app_colors.dart` semantic tokens.
- **Equatable** (or freezed if introduced later) for Bloc states/events compared in tests.
- Prefer **`bloc_concurrency`** transformers where search/refresh can overlap (document in bloc file).

## Naming

| Item | Convention |
|------|------------|
| Files | `snake_case.dart` |
| Classes | `PascalCase` |
| Bloc events | past tense / imperative verb (`MarketsRequested`, `SearchQueryChanged`) |
| Repository impl | `*_repository_impl.dart` |
| Data sources | `*_remote_data_source.dart`, `*_local_data_source.dart` |
| Tests | mirror `test/` path under `lib/` |

## Tests (required per PR)

Every PR must include tests matching its roadmap step **acceptance criteria**. Minimum:

- **Bloc/Cubit** — `bloc_test` for happy path + one failure path.
- **Repository** — mock data sources or HTTP client; verify cache-first when applicable.
- **PriceStreamService** — use `FakePriceStreamService`, not live Binance, in CI.

Do not merge with failing CI.

## Dependencies

Add packages only with a one-line justification in PR description (see README tech stack). Avoid duplicate state management or DI libraries.

## Documentation

When behaviour changes APIs, TTLs, or endpoints, update the matching file under `docs/` in the same PR. Keep `README.md` run instructions accurate after step 1.

## Secrets

- CoinGecko Demo key via **`--dart-define=COINGECKO_DEMO_API_KEY`**.
- Never commit `.env` with keys; use CI secrets only for optional integration jobs.

## Git workflow

- Branch prefix: `cursor/` when created by agents.
- One roadmap step per PR; do not combine steps 3 and 4 without owner approval.
- Commit messages: complete sentences, imperative mood (`Add markets repository cache-first loading`).

## Questions to escalate to owner

- Background WebSocket policy (disconnect vs keep-alive).
- Serbian locale code (`sr` vs `sr_Latn`).
- Chart primary source when Binance pair missing (CG-only vs hide coin).
- Hive vs Drift if watchlist complexity grows.
