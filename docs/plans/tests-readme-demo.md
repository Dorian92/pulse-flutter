# Step 8 — Tests, README, architecture & demo

## Scope

Close meaningful test gaps after steps 1–7, ship a portfolio-quality README, refresh `docs/architecture.md` (testing, offline, realtime merge), produce fixture-based demo media under `docs/demo/`, and keep CI green with zero analyzer issues.

**Out of scope:** React Native twin, live-network tests in CI, golden tests on CI, coverage gates that fail the build.

## Coverage audit

Command: `flutter test --coverage` then sum `LH`/`LF` in `coverage/lcov.info` (lib/ only).

| Metric | Before step 8 | After step 8 |
|--------|----------------|--------------|
| Line coverage (lib/) | **~74.9%** (2952 / 3942) | **~76.3%** (3008 / 3942) |

### Gaps addressed

| Area | Action |
|------|--------|
| **Core** | `stable_hash`, `PreferencesStore`, `WatchlistMarketsDataSource`, toggle adapter |
| **Blocs / UI** | `test/pulse_happy_path_test.dart` + `integration_test/app_test.dart` (device, local only) |
| **Debug / l10n gen** | Intentionally low priority |

## Acceptance criteria

- [x] `docs/plans/tests-readme-demo.md` committed before implementation PR
- [x] `flutter analyze` — zero issues
- [x] `dart format lib test integration_test tool` clean
- [x] `flutter test --coverage` green in CI (no device integration job)
- [x] Line coverage before/after documented
- [x] README screenshot grid + demo under `docs/demo/`
- [x] `docs/architecture.md` updated (testing, diagrams, accurate tree)
- [x] Demo media in repo (+ agent artifacts when built)
- [x] Happy path: markets → detail → watchlist (widget test in CI; device test local)
- [x] EN + `sr_Latn` unchanged for this step

## Review follow-up (PR #14)

- **Integration tests:** CI guard stays **`test/pulse_happy_path_test.dart`** (`AppRoutes` shell + injected test blocs; avoids widget-binding stall when real watchlist membership listeners run). **`integration_test/app_test.dart`** uses **`PulseApp`**, **`initPulseTestDependencies()`**, and shared **`pulse_happy_path_flow.dart`** for `flutter test integration_test -d <device>` locally; not added to CI.
- **Shared flow:** `test/helpers/pulse_happy_path_flow.dart` to avoid drift.
- **Format scope:** CI and README both use `dart format … lib test integration_test tool`.

## Test commands

```bash
# CI-equivalent (no live network)
dart format lib test integration_test tool
flutter analyze
flutter test --coverage
bash tool/check_generated.sh

# Widget happy path only
flutter test test/pulse_happy_path_test.dart

# Device / emulator (local)
flutter test integration_test/app_test.dart -d <deviceId>

# Optional: screenshots / demo
bash tool/screenshots.sh
bash tool/build_demo.sh
```
