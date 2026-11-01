# Step 8 — Tests, README, architecture & demo

## Scope

Close meaningful test gaps after steps 1–7, ship a portfolio-quality README, refresh `docs/architecture.md` (testing, offline, realtime merge), produce fixture-based demo media under `docs/demo/`, and keep CI green with zero analyzer issues.

**Out of scope:** React Native twin, live-network integration tests, golden tests on CI, coverage gates that fail the build.

## Coverage audit (baseline)

Command: `flutter test --coverage` then sum `LH`/`LF` in `coverage/lcov.info`.

| Metric | Before step 8 |
|--------|----------------|
| Line coverage (lib/) | **~74.9%** (2952 / 3942 lines) |

### Gaps to address

| Area | Finding | Action |
|------|---------|--------|
| **Core** | `stable_hash.dart`, `watchlist_toggle_adapter.dart` untested | Unit tests for hash stability and toggle delegation |
| **Core** | `watchlist_markets_data_source.dart` ~2% | Repository-style tests with mock `ApiClient` + fake cache |
| **Core** | `ApiClient` / `CacheStore` / `SymbolMapper` | Already strong; add cache-key / stale path for watchlist fetch only |
| **Realtime** | Binance service + coordinator | Already covered in step 5 tests; no new live code |
| **Blocs / UI** | End-to-end navigation with real DI | **Integration-style flow** (markets → coin detail → watchlist star) using fakes, no network |
| **Debug / l10n gen** | `design_gallery_page`, generated l10n | Intentionally low priority (debug-only / generated) |

After step 8, target **≥76%** line coverage on `lib/` without chasing generated or debug-only files.

## README plan

Replace TBD demo section with:

- One-line pitch + feature bullets
- Screenshot grid linking `docs/screenshots/*_fixture.png` (fixture data labeled in filenames)
- Tech stack table (unchanged sources)
- Mermaid architecture diagram (high level)
- Run / test / coverage commands (with and without CoinGecko key for optional live runs)
- Project structure tree (abbreviated)
- Key trade-offs (CoinGecko + Binance, single WS, Hive, EUR via EURUSDT)
- Roadmap pointer + known limitations
- MIT license

## Architecture doc plan

Update existing `docs/architecture.md` (no duplicate file):

- Expand **testing strategy** (unit / bloc / widget / integration / fakes / screenshot harness)
- Add mermaid for **REST cache-first + stale fallback** and **live tick merge**
- Clarify **offline / stale** UX contract with repositories
- Note **integration_test** happy path and `FakePriceStreamService` policy

## Demo plan

No physical device in cloud CI:

1. Reuse ordered fixture PNGs from `docs/screenshots/` (or re-render via `tool/screenshot_capture_test.dart` when needed).
2. Stitch with **ffmpeg** → `docs/demo/pulse_demo.mp4` and `pulse_demo.gif` (overlay text: fixture data).
3. Copy artifacts to `/opt/cursor/artifacts/demo/`.

Fallback if ffmpeg fails: animated GIF from ImageMagick or static README link to MP4 only.

Optional CI step: print `lcov --summary` after tests (informational only, no threshold).

## Acceptance criteria

- [ ] `docs/plans/tests-readme-demo.md` committed before implementation PR
- [ ] `flutter analyze` — zero issues
- [ ] `dart format lib test integration_test tool` clean
- [ ] `flutter test` and `flutter test integration_test` green locally and in CI
- [ ] Line coverage on `lib/` documented before/after (no failing coverage gate)
- [ ] README includes screenshot grid + demo link to `docs/demo/`
- [ ] `docs/architecture.md` updated with testing + data-flow diagrams
- [ ] Demo media present under `docs/demo/` and `/opt/cursor/artifacts/`
- [ ] At least one integration test: markets list → open coin detail → toggle watchlist (fakes)
- [ ] EN + `sr_Latn` ARB unchanged unless new strings added

## Test commands

```bash
# Default CI suite (no live network)
flutter test --coverage

# Integration flow (same fakes as widget bootstrap)
flutter test integration_test

# Optional: regenerate fixture screenshots (local / agent only)
bash tool/screenshots.sh

# Demo stitch (fixture frames)
bash tool/build_demo.sh
```
