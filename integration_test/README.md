# Integration-style flows

CI runs end-to-end behaviour on the **widget test harness** (no device, no live network) via these tests:

| Step | Test |
|------|------|
| Markets list | `test/app_router_test.dart` — `PulseApp` boots and shows Bitcoin |
| Open coin detail | `test/markets/ui/markets_page_test.dart` — row tap navigates to detail |
| Toggle watchlist | `test/coin_detail/ui/coin_detail_page_test.dart` — star dispatches toggle |

Run them together:

```bash
flutter test test/app_router_test.dart test/markets/ui/markets_page_test.dart test/coin_detail/ui/coin_detail_page_test.dart
```

Device-based `integration_test` package runs are optional for local manual QA.
