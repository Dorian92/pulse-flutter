import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/core/realtime/fake_price_stream_service.dart';
import '../test/helpers/pulse_happy_path_flow.dart';
import '../test/helpers/pulse_test_bootstrap.dart';

/// Device / emulator flow (not run in CI). Requires:
/// `flutter test integration_test -d <deviceId>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initPulseTestDependencies(
      priceStreamService: FakePriceStreamService(),
      connectivityService: FakeConnectivityService(),
    );
  });

  testWidgets('markets → coin detail → watchlist on device', (tester) async {
    await runMarketsDetailWatchlistHappyPath(tester);
  });
}
