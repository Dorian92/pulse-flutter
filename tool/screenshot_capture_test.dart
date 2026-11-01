@Tags(['screenshots'])
library;

import 'dart:math' as math;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/debug/ui/design_gallery_page.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/settings/ui/settings_page.dart';
import 'package:pulse/shell/ui/main_shell.dart';

import 'screenshot_support.dart';

class MockMarketsBloc extends MockBloc<MarketsEvent, MarketsState>
    implements MarketsBloc {}

class MockCoinDetailBloc extends MockBloc<CoinDetailEvent, CoinDetailState>
    implements CoinDetailBloc {}

MarketsSnapshot _marketsSnapshot({required DateTime fetchedAt}) {
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
        currentPriceEur: 69705,
        priceChangePercent24h: 2.4,
        marketCapRank: 1,
        sparkline7d: [1, 1.1, 1.05, 1.2, 1.15, 1.25, 1.3],
        binanceSymbol: 'BTCUSDT',
      ),
      MarketCoin(
        id: 'ethereum',
        symbol: 'eth',
        name: 'Ethereum',
        imageUrl: '',
        currentPriceEur: 3200,
        priceChangePercent24h: -0.8,
        marketCapRank: 2,
        sparkline7d: [2, 1.9, 2.1, 2.0, 1.95, 2.05, 2.1],
        binanceSymbol: 'ETHUSDT',
      ),
      MarketCoin(
        id: 'solana',
        symbol: 'sol',
        name: 'Solana',
        imageUrl: '',
        currentPriceEur: 145,
        priceChangePercent24h: 5.2,
        marketCapRank: 5,
        sparkline7d: [1, 1.2, 1.4, 1.3, 1.5, 1.6, 1.7],
        binanceSymbol: 'SOLUSDT',
      ),
      MarketCoin(
        id: 'pepe',
        symbol: 'pepe',
        name: 'Pepe',
        imageUrl: '',
        currentPriceEur: 0.42,
        priceChangePercent24h: -3.1,
        marketCapRank: 120,
        sparkline7d: [1, 0.9, 0.85, 0.8],
      ),
    ],
  );
}

MarketsState _marketsLoaded({
  MarketFilter filter = MarketFilter.all,
  String searchQuery = '',
  bool isStale = false,
  DateTime? fetchedAt,
  RealtimeStatus realtime = const RealtimeStatus.live(),
  int liveFlashGeneration = 0,
  String? liveFlashCoinId,
}) {
  final snapshot = _marketsSnapshot(
    fetchedAt: fetchedAt ?? DateTime.utc(2026, 11, 1, 12),
  );
  final visible = MarketsBloc.applyFilters(
    coins: snapshot.coins,
    query: searchQuery,
    filter: filter,
  );
  return MarketsState(
    status: MarketsStatus.loaded,
    snapshot: snapshot,
    visibleCoins: visible,
    isStale: isStale,
    searchQuery: searchQuery,
    filter: filter,
    realtimeStatus: realtime,
    liveFlashGeneration: liveFlashGeneration,
    liveFlashCoinId: liveFlashCoinId,
  );
}

void _stubMarketsBloc(MockMarketsBloc bloc, MarketsState state) {
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => bloc.add(any())).thenReturn(null);
}

Widget _marketsApp({
  required MarketsBloc bloc,
  ThemeMode themeMode = ThemeMode.dark,
  Locale? locale,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.markets,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.show_chart_outlined),
                  label: AppLocalizations.of(context)!.tabMarkets,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.star_outline),
                  label: AppLocalizations.of(context)!.tabWatchlist,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: AppLocalizations.of(context)!.tabSettings,
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.markets,
            builder: (context, state) => MarketsPage(bloc: bloc),
          ),
        ],
      ),
    ],
  );

  return screenshotBoundary(
    child: MaterialApp.router(
      debugShowCheckedModeBanner: screenshotDebugShowCheckedModeBanner,
      theme: prepareScreenshotTheme(AppTheme.light()),
      darkTheme: prepareScreenshotTheme(AppTheme.dark()),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

CoinDetailState _coinDetailLoaded() {
  final start = DateTime.utc(2026, 10, 28, 8);
  final points = List.generate(24, (i) {
    final wiggle = math.sin(i * 0.85) * 650 + math.cos(i * 0.35) * 320;
    final drift = i * 28.0;
    return ChartPoint(
      timestamp: start.add(Duration(hours: i)),
      priceEur: 68400 + drift + wiggle,
    );
  });
  return CoinDetailState.loaded(
    coinId: 'bitcoin',
    detail: CoinDetail(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      imageUrl: '',
      currentPriceEur: 69705,
      priceChangePercent24h: 2.4,
      marketCapEur: 1.35e12,
      volume24hEur: 28e9,
      high24hEur: 70500,
      low24hEur: 66800,
      circulatingSupply: 19.8e6,
      athEur: 73000,
      aboutTextEn:
          'Bitcoin is a decentralized digital currency without a central bank.',
      fetchedAt: DateTime.utc(2026, 11, 1, 12),
      binanceSymbol: 'BTCUSDT',
    ),
    chart: PriceChartSeries(
      points: points,
      range: ChartPeriod.oneDay,
      source: ChartDataSource.coinGeckoMarketChart,
      fetchedAt: DateTime.utc(2026, 11, 1, 12),
    ),
    selectedRange: ChartPeriod.oneDay,
    livePriceEur: 69705,
    changePercent24h: 2.4,
    realtimeStatus: const RealtimeStatus.live(),
    isStale: false,
    chartLoading: false,
    isWatchlisted: true,
  );
}

void main() {
  setUpAll(() async {
    registerFallbackValue(const MarketsRequested());
    registerFallbackValue(
      const CoinDetailChartRangeChanged(ChartPeriod.oneDay),
    );
    await loadScreenshotFonts();
  });

  group('Pulse fixture screenshots', () {
    testWidgets('01_markets_dark_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(bloc, _marketsLoaded());

      await tester.pumpWidget(_marketsApp(bloc: bloc));
      await captureScreenshotPng(tester, '01_markets_dark_fixture.png');
    });

    testWidgets('02_markets_light_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(bloc, _marketsLoaded());

      await tester.pumpWidget(
        _marketsApp(bloc: bloc, themeMode: ThemeMode.light),
      );
      await captureScreenshotPng(tester, '02_markets_light_fixture.png');
    });

    testWidgets('03_markets_gainers_filter_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(bloc, _marketsLoaded(filter: MarketFilter.gainers));

      await tester.pumpWidget(_marketsApp(bloc: bloc));
      await captureScreenshotPng(
        tester,
        '03_markets_gainers_filter_fixture.png',
      );
    });

    testWidgets('04_markets_search_active_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(bloc, _marketsLoaded(searchQuery: 'bit'));

      await tester.pumpWidget(_marketsApp(bloc: bloc));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 200));
      await captureScreenshotPng(
        tester,
        '04_markets_search_active_fixture.png',
      );
    });

    testWidgets('05_markets_loading_shimmer_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      when(() => bloc.state).thenReturn(const MarketsState.loading());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.add(any())).thenReturn(null);

      await tester.pumpWidget(_marketsApp(bloc: bloc));
      await captureScreenshotPng(
        tester,
        '05_markets_loading_shimmer_fixture.png',
      );
    });

    testWidgets('06_markets_offline_stale_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(
        bloc,
        _marketsLoaded(
          isStale: true,
          fetchedAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 14),
          ),
          realtime: const RealtimeStatus.offline(),
        ),
      );

      await tester.pumpWidget(_marketsApp(bloc: bloc));
      await captureScreenshotPng(
        tester,
        '06_markets_offline_stale_fixture.png',
      );
    });

    testWidgets('07_design_gallery_dark_fixture', (tester) async {
      await configurePhoneSurface(tester);
      await tester.pumpWidget(
        screenshotBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: screenshotDebugShowCheckedModeBanner,
            theme: prepareScreenshotTheme(AppTheme.dark()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DesignGalleryPage(),
          ),
        ),
      );
      await captureScreenshotPng(tester, '07_design_gallery_dark_fixture.png');
    });

    testWidgets('08_design_gallery_light_scrolled_fixture', (tester) async {
      await configurePhoneSurface(tester);
      await tester.pumpWidget(
        screenshotBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: screenshotDebugShowCheckedModeBanner,
            theme: prepareScreenshotTheme(AppTheme.dark()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DesignGalleryPage(),
          ),
        ),
      );
      await tester.tap(find.text('Toggle theme'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.drag(find.byType(ListView), const Offset(0, -480));
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenshotPng(
        tester,
        '08_design_gallery_light_scrolled_fixture.png',
      );
    });

    testWidgets('09_settings_tab_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final router = GoRouter(
        initialLocation: AppRoutes.settings,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.markets,
                    builder: (context, state) => const SizedBox.shrink(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.watchlist,
                    builder: (context, state) => const SizedBox.shrink(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    builder: (context, state) => const SettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        screenshotBoundary(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: screenshotDebugShowCheckedModeBanner,
            theme: prepareScreenshotTheme(AppTheme.light()),
            darkTheme: prepareScreenshotTheme(AppTheme.dark()),
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await captureScreenshotPng(tester, '09_settings_tab_fixture.png');
    });

    testWidgets('10_markets_serbian_locale_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockMarketsBloc();
      _stubMarketsBloc(bloc, _marketsLoaded());

      await tester.pumpWidget(
        _marketsApp(bloc: bloc, locale: const Locale('sr', 'Latn')),
      );
      await captureScreenshotPng(
        tester,
        '10_markets_serbian_locale_fixture.png',
      );
    });

    testWidgets('11_coin_detail_chart_fixture', (tester) async {
      await configurePhoneSurface(tester);
      final bloc = MockCoinDetailBloc();
      when(() => bloc.state).thenReturn(_coinDetailLoaded());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.add(any())).thenReturn(null);

      await tester.pumpWidget(
        screenshotBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: screenshotDebugShowCheckedModeBanner,
            theme: prepareScreenshotTheme(AppTheme.dark()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CoinDetailPage(coinId: 'bitcoin', bloc: bloc),
          ),
        ),
      );
      await captureScreenshotPng(tester, '11_coin_detail_chart_fixture.png');
    });
  });
}
