import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/theme/app_theme.dart';
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
    ],
  );
}

void main() {
  late MockMarketsBloc bloc;

  setUp(() {
    bloc = MockMarketsBloc();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<MarketsBloc>.value(value: bloc, child: child),
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

    await tester.pumpWidget(wrap(MarketsPage(bloc: bloc)));
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

    await tester.pumpWidget(wrap(MarketsPage(bloc: bloc)));
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

    await tester.pumpWidget(wrap(MarketsPage(bloc: bloc)));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
