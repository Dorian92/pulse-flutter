import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

/// Shared markets → detail → watchlist star flow for device [integration_test].
///
/// Call after [initPulseTestDependencies] with fakes (no live network).
/// Uses bounded pumps after watchlist persistence (full [pumpAndSettle] can
/// stall the widget test binding once membership listeners run).
Future<void> runMarketsDetailWatchlistHappyPath(WidgetTester tester) async {
  await tester.pumpWidget(const PulseApp());
  await tester.pumpAndSettle();
  expect(find.text('Bitcoin'), findsWidgets);

  await tester.tap(find.text('Bitcoin').first);
  await _pumpUntil(
    tester,
    () => find.byType(CoinDetailPage).evaluate().isNotEmpty,
  );
  expect(find.byType(CoinDetailPage), findsOneWidget);

  await tester.tap(find.byTooltip('Add to watchlist'));
  await _pumpUntil(
    tester,
    () async => sl<WatchlistRepository>().isWatched('bitcoin'),
  );
  expect(await sl<WatchlistRepository>().isWatched('bitcoin'), isTrue);

  await tester.tap(find.byType(BackButton));
  await _pumpUntil(
    tester,
    () => find.byType(MarketsPage).evaluate().isNotEmpty,
  );

  await tester.tap(find.byIcon(Icons.star_outline));
  await _pumpUntil(
    tester,
    () => find.byType(WatchlistPage).evaluate().isNotEmpty,
  );
  expect(find.byType(WatchlistPage), findsOneWidget);

  final watchlistBitcoin = find.descendant(
    of: find.byType(WatchlistPage),
    matching: find.text('Bitcoin'),
  );
  await _pumpUntil(tester, () => watchlistBitcoin.evaluate().isNotEmpty);
  expect(watchlistBitcoin, findsWidgets);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  FutureOr<bool> Function() condition, {
  int maxSteps = 50,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (await condition()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for happy-path condition');
}
