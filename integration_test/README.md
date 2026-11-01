# Integration-style flows

## CI (widget harness)

**`test/pulse_happy_path_test.dart`** runs the full flow with real `PulseApp`, production router wiring, and `initPulseTestDependencies()` fakes (no live network):

Markets list → coin detail → watchlist star → watchlist tab shows Bitcoin.

```bash
flutter test test/pulse_happy_path_test.dart
```

Shared steps live in **`test/helpers/pulse_happy_path_flow.dart`**.

## Local device / emulator (not CI)

**`integration_test/app_test.dart`** runs the same helper on a attached device:

```bash
flutter test integration_test/app_test.dart -d <deviceId>
```

Example: `flutter devices` then `flutter test integration_test -d emulator-5554`.

Device integration tests are intentionally **excluded from GitHub Actions** (headless Linux runs were unreliable).
