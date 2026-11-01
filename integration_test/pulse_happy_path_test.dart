import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pulse/app.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

import '../test/helpers/pulse_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initPulseTestDependencies();
  });

  testWidgets('markets list → coin detail → watchlist toggle', (tester) async {
    await tester.pumpWidget(const PulseApp());
    await tester.pumpAndSettle();

    expect(find.byType(MarketsPage), findsOneWidget);
    expect(find.text('Bitcoin'), findsWidgets);

    await tester.tap(find.text('Bitcoin').first);
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();

    expect(find.byType(WatchlistPage), findsOneWidget);
    expect(find.text('Bitcoin'), findsWidgets);
  });
}
