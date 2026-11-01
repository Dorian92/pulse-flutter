import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/core/widgets/no_live_feed_badge.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/ui/markets_page.dart';

class MockMarketsBloc extends MockBloc<MarketsEvent, MarketsState>
    implements MarketsBloc {}

MarketsSnapshot _snapshot({required DateTime fetchedAt}) {
  return MarketsSnapshot(
    fetchedAt: fetchedAt,
    global: const GlobalMarketSummary(
      totalMarketCapEur: 2.31e12,
      marketCapChangePercent24h: 1.8,
    ),
    coins: const [
      MarketCoin(
        id: 'bitcoin',
        symbol: 'btc',
        name: 'Bitcoin',
        imageUrl: '',
        currentPriceEur: 95000,
        priceChangePercent24h: 2,
        marketCapRank: 1,
        sparkline7d: [1, 2, 3],
        binanceSymbol: 'BTCUSDT',
      ),
      MarketCoin(
        id: 'unknown-alt',
        symbol: 'unk',
        name: 'Unknown Alt',
        imageUrl: '',
        currentPriceEur: 1,
        priceChangePercent24h: -1,
        marketCapRank: 99,
        sparkline7d: [1],
      ),
    ],
  );
}

void main() {
  late MockMarketsBloc bloc;

  setUp(() {
    bloc = MockMarketsBloc();
  });

  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: AppRoutes.markets,
      routes: [
        GoRoute(
          path: AppRoutes.markets,
          builder: (context, state) =>
              BlocProvider<MarketsBloc>.value(value: bloc, child: child),
        ),
        GoRoute(
          path: AppRoutes.coinDetail,
          builder: (context, state) {
            final coinId = state.pathParameters['coinId'] ?? '';
            return Scaffold(body: Text('detail:$coinId'));
          },
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('shows shimmer while loading without data', (tester) async {
    when(() => bloc.state).thenReturn(const MarketsState.loading());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    whenListen(
      bloc,
      Stream.value(const MarketsState.loading()),
      initialState: const MarketsState.loading(),
    );

    await tester.pumpWidget(wrapWithRouter(MarketsPage(bloc: bloc)));
    await tester.pump();

    expect(find.byType(ShimmerSkeleton), findsWidgets);
  });

  testWidgets('shows offline banner when stale', (tester) async {
    final fetchedAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 12),
    );
    whenListen(
      bloc,
      Stream.value(
        MarketsState.loaded(
          snapshot: _snapshot(fetchedAt: fetchedAt),
          visibleCoins: _snapshot(fetchedAt: fetchedAt).coins,
          isStale: true,
        ),
      ),
      initialState: MarketsState.loaded(
        snapshot: _snapshot(fetchedAt: fetchedAt),
        visibleCoins: _snapshot(fetchedAt: fetchedAt).coins,
        isStale: true,
      ),
    );

    await tester.pumpWidget(wrapWithRouter(MarketsPage(bloc: bloc)));
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('Bitcoin'), findsOneWidget);
  });

  testWidgets('shows retry on failure without cache', (tester) async {
    whenListen(
      bloc,
      Stream.value(
        const MarketsState.failure(failure: NetworkFailure(offline: true)),
      ),
      initialState: const MarketsState.failure(
        failure: NetworkFailure(offline: true),
      ),
    );

    await tester.pumpWidget(wrapWithRouter(MarketsPage(bloc: bloc)));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('row tap navigates to coin detail route', (tester) async {
    final fetchedAt = DateTime.utc(2026, 6, 1, 12);
    final snapshot = _snapshot(fetchedAt: fetchedAt);
    whenListen(
      bloc,
      Stream.value(
        MarketsState.loaded(snapshot: snapshot, visibleCoins: snapshot.coins),
      ),
      initialState: MarketsState.loaded(
        snapshot: snapshot,
        visibleCoins: snapshot.coins,
      ),
    );

    await tester.pumpWidget(wrapWithRouter(MarketsPage(bloc: bloc)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bitcoin'));
    await tester.pumpAndSettle();

    expect(find.text('detail:bitcoin'), findsOneWidget);
  });

  testWidgets('shows no live feed badge for unmapped symbol', (tester) async {
    final fetchedAt = DateTime.utc(2026, 6, 1, 12);
    final snapshot = _snapshot(fetchedAt: fetchedAt);
    whenListen(
      bloc,
      Stream.value(
        MarketsState.loaded(snapshot: snapshot, visibleCoins: snapshot.coins),
      ),
      initialState: MarketsState.loaded(
        snapshot: snapshot,
        visibleCoins: snapshot.coins,
      ),
    );

    await tester.pumpWidget(wrapWithRouter(MarketsPage(bloc: bloc)));
    await tester.pumpAndSettle();

    expect(find.byType(NoLiveFeedBadge), findsOneWidget);
    expect(find.text('No live feed'), findsOneWidget);
  });
}
