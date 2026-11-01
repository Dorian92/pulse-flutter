import 'dart:async';

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
import 'package:pulse/watchlist/bloc/watchlist_bloc.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

class MockMarketsBloc extends MockBloc<MarketsEvent, MarketsState>
    implements MarketsBloc {}

class MockCoinDetailBloc extends MockBloc<CoinDetailEvent, CoinDetailState>
    implements CoinDetailBloc {}

class MockWatchlistBloc extends MockBloc<WatchlistEvent, WatchlistState>
    implements WatchlistBloc {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

CoinDetailState _detailLoaded({required bool isWatchlisted}) {
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
    isWatchlisted: isWatchlisted,
  );
}

WatchlistState _watchlistWithBitcoin() {
  const coin = MarketCoin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 1,
    priceChangePercent24h: 1,
    marketCapRank: 1,
    sparkline7d: [1, 2, 3],
    binanceSymbol: 'BTCUSDT',
  );
  return WatchlistState(
    status: WatchlistStatus.loaded,
    entries: const [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
    isStale: false,
    isEditing: false,
    realtimeStatus: const RealtimeStatus.offline(),
    fetchedAt: DateTime.utc(2026, 6, 1, 12),
  );
}

void main() {
  late MockMarketsBloc marketsBloc;
  late MockCoinDetailBloc detailBloc;
  late MockWatchlistBloc watchlistBloc;
  late MockSettingsCubit settingsCubit;

  setUpAll(() {
    registerFallbackValue(const CoinDetailWatchlistToggled());
  });

  setUp(() {
    marketsBloc = MockMarketsBloc();
    detailBloc = MockCoinDetailBloc();
    watchlistBloc = MockWatchlistBloc();
    settingsCubit = MockSettingsCubit();
    when(() => settingsCubit.state).thenReturn(const SettingsState.initial());
    when(
      () => settingsCubit.stream,
    ).thenAnswer((_) => Stream.value(const SettingsState.initial()));
  });

  tearDown(() async {
    await settingsCubit.close();
  });

  testWidgets(
    'markets → coin detail → watchlist (AppRoutes + test blocs, CI guard)',
    (tester) async {
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

      final detailStates = StreamController<CoinDetailState>();
      final watchlistStates = StreamController<WatchlistState>();
      addTearDown(() async {
        await detailStates.close();
        await watchlistStates.close();
      });

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
        detailStates.stream,
        initialState: _detailLoaded(isWatchlisted: false),
      );

      whenListen(
        watchlistBloc,
        watchlistStates.stream,
        initialState: const WatchlistState.initial(),
      );

      when(() => detailBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments.first
            is CoinDetailWatchlistToggled) {
          detailStates.add(_detailLoaded(isWatchlisted: true));
          watchlistStates.add(_watchlistWithBitcoin());
        }
      });

      final router = GoRouter(
        initialLocation: AppRoutes.markets,
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              final location = state.uri.path;
              var selectedIndex = 0;
              if (location.startsWith(AppRoutes.watchlist)) {
                selectedIndex = 1;
              }
              return Scaffold(
                body: child,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        context.go(AppRoutes.markets);
                      case 1:
                        context.go(AppRoutes.watchlist);
                      default:
                        break;
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.show_chart_outlined),
                      label: 'Markets',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.star_outline),
                      label: 'Watchlist',
                    ),
                  ],
                ),
              );
            },
            routes: [
              GoRoute(
                path: AppRoutes.markets,
                builder: (context, state) => MarketsPage(bloc: marketsBloc),
              ),
              GoRoute(
                path: AppRoutes.watchlist,
                builder: (context, state) => WatchlistPage(bloc: watchlistBloc),
              ),
            ],
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

      await tester.tap(find.byTooltip('Add to watchlist'));
      await tester.pumpAndSettle();
      verify(
        () => detailBloc.add(const CoinDetailWatchlistToggled()),
      ).called(1);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();
      expect(find.byType(WatchlistPage), findsOneWidget);
      expect(find.text('Bitcoin'), findsWidgets);
    },
  );
}
