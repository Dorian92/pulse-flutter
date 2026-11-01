import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/bloc/coin_detail_bloc.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/bloc/settings_state.dart';

class MockMarketsBloc extends MockBloc<MarketsEvent, MarketsState>
    implements MarketsBloc {}

class MockCoinDetailBloc extends MockBloc<CoinDetailEvent, CoinDetailState>
    implements CoinDetailBloc {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

CoinDetailState _detailLoaded() {
  final fetchedAt = DateTime.utc(2026, 6, 1, 12);
  return CoinDetailState.loaded(
    coinId: 'bitcoin',
    detail: CoinDetail(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      imageUrl: '',
      currentPriceEur: 1,
      priceChangePercent24h: 1,
      marketCapEur: 1,
      volume24hEur: 1,
      high24hEur: 1,
      low24hEur: 1,
      circulatingSupply: 1,
      athEur: 1,
      aboutTextEn: 'About',
      fetchedAt: fetchedAt,
      binanceSymbol: 'BTCUSDT',
    ),
    chart: PriceChartSeries(
      points: [
        ChartPoint(timestamp: fetchedAt, priceEur: 1),
        ChartPoint(
          timestamp: fetchedAt.add(const Duration(hours: 1)),
          priceEur: 2,
        ),
      ],
      range: ChartPeriod.oneDay,
      source: ChartDataSource.coinGeckoMarketChart,
      fetchedAt: fetchedAt,
    ),
    selectedRange: ChartPeriod.oneDay,
    livePriceEur: 1,
    changePercent24h: 1,
    realtimeStatus: const RealtimeStatus.offline(),
    isStale: false,
    chartLoading: false,
    isWatchlisted: false,
  );
}

void main() {
  late MockMarketsBloc marketsBloc;
  late MockCoinDetailBloc detailBloc;
  late MockSettingsCubit settingsCubit;

  setUpAll(() {
    registerFallbackValue(const CoinDetailWatchlistToggled());
  });

  setUp(() {
    marketsBloc = MockMarketsBloc();
    detailBloc = MockCoinDetailBloc();
    settingsCubit = MockSettingsCubit();
    when(() => settingsCubit.state).thenReturn(const SettingsState.initial());
    when(
      () => settingsCubit.stream,
    ).thenAnswer((_) => Stream.value(const SettingsState.initial()));
  });

  tearDown(() async {
    await settingsCubit.close();
  });

  testWidgets('markets → coin detail → watchlist toggle (mocked blocs)', (
    tester,
  ) async {
    final fetchedAt = DateTime.utc(2026, 6, 1, 12);
    final snapshot = MarketsSnapshot(
      fetchedAt: fetchedAt,
      global: const GlobalMarketSummary(
        totalMarketCapEur: 1,
        marketCapChangePercent24h: 1,
      ),
      coins: const [
        MarketCoin(
          id: 'bitcoin',
          symbol: 'btc',
          name: 'Bitcoin',
          imageUrl: '',
          currentPriceEur: 1,
          priceChangePercent24h: 1,
          marketCapRank: 1,
          sparkline7d: [1, 2, 3],
          binanceSymbol: 'BTCUSDT',
        ),
      ],
    );

    whenListen(
      marketsBloc,
      Stream.value(
        MarketsState.loaded(snapshot: snapshot, visibleCoins: snapshot.coins),
      ),
      initialState: MarketsState.loaded(
        snapshot: snapshot,
        visibleCoins: snapshot.coins,
      ),
    );

    whenListen(
      detailBloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _detailLoaded(),
    );
    when(() => detailBloc.add(any())).thenReturn(null);

    final router = GoRouter(
      initialLocation: AppRoutes.markets,
      routes: [
        GoRoute(
          path: AppRoutes.markets,
          builder: (context, state) => MarketsPage(bloc: marketsBloc),
        ),
        GoRoute(
          path: AppRoutes.coinDetail,
          builder: (context, state) {
            final coinId = state.pathParameters['coinId'] ?? '';
            return CoinDetailPage(coinId: coinId, bloc: detailBloc);
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<SettingsCubit>.value(
        value: settingsCubit,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bitcoin'));
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();

    verify(() => detailBloc.add(const CoinDetailWatchlistToggled())).called(1);
  });
}
