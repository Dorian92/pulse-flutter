import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/bloc/coin_detail_bloc.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/core/widgets/live_indicator.dart';
import 'package:pulse/core/widgets/no_live_feed_badge.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/l10n/app_localizations.dart';

class MockCoinDetailBloc extends MockBloc<CoinDetailEvent, CoinDetailState>
    implements CoinDetailBloc {}

CoinDetail _detail({String? binanceSymbol}) {
  return CoinDetail(
    id: 'chainlink',
    symbol: 'LINK',
    name: 'Chainlink',
    imageUrl: '',
    currentPriceEur: 20,
    priceChangePercent24h: -0.5,
    marketCapEur: 1e9,
    volume24hEur: 1e8,
    high24hEur: 21,
    low24hEur: 19,
    circulatingSupply: 1e9,
    athEur: 50,
    aboutTextEn: 'Decentralized oracle network.',
    fetchedAt: DateTime.utc(2026),
    binanceSymbol: binanceSymbol,
  );
}

CoinDetailState _loadedState({String? binanceSymbol}) {
  return CoinDetailState.loaded(
    coinId: 'chainlink',
    detail: _detail(binanceSymbol: binanceSymbol),
    chart: PriceChartSeries(
      points: [
        ChartPoint(timestamp: DateTime.utc(2026), priceEur: 19),
        ChartPoint(timestamp: DateTime.utc(2026, 1, 2), priceEur: 20),
      ],
      range: ChartPeriod.oneDay,
      source: ChartDataSource.coinGeckoMarketChart,
      fetchedAt: DateTime.utc(2026, 1, 2),
    ),
    selectedRange: ChartPeriod.oneDay,
    livePriceEur: 20,
    changePercent24h: -0.5,
    realtimeStatus: const RealtimeStatus.offline(),
    isStale: false,
    chartLoading: false,
    isWatchlisted: false,
  );
}

Widget _wrap(CoinDetailBloc bloc) {
  return MaterialApp(
    theme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CoinDetailPage(coinId: 'test', bloc: bloc),
  );
}

void main() {
  late MockCoinDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const CoinDetailChartRangeChanged(ChartPeriod.oneDay),
    );
  });

  setUp(() {
    bloc = MockCoinDetailBloc();
  });

  testWidgets('shows shimmer while loading', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: CoinDetailState.loading(coinId: 'bitcoin'),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.byType(ShimmerSkeleton), findsWidgets);
  });

  testWidgets('shows no live feed badge when pair missing', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.byType(NoLiveFeedBadge), findsOneWidget);
  });

  testWidgets('period tap dispatches range changed', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(binanceSymbol: 'BTCUSDT'),
    );
    when(() => bloc.add(any())).thenReturn(null);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    await tester.tap(find.text('1W'));
    await tester.pump();

    verify(
      () => bloc.add(const CoinDetailChartRangeChanged(ChartPeriod.oneWeek)),
    ).called(1);
  });

  testWidgets('shows offline banner when stale', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(
        binanceSymbol: 'BTCUSDT',
      ).copyWith(isStale: true, fetchedAt: DateTime.utc(2026, 1, 1, 10)),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.byType(OfflineBanner), findsOneWidget);
  });

  testWidgets('shows active live indicator when status live', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(
        binanceSymbol: 'BTCUSDT',
      ).copyWith(realtimeStatus: const RealtimeStatus.live()),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.byType(LiveIndicator), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('chart error retry dispatches range reload', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: CoinDetailState.loaded(
        coinId: 'chainlink',
        detail: _detail(binanceSymbol: 'BTCUSDT'),
        selectedRange: ChartPeriod.oneDay,
        livePriceEur: 20,
        changePercent24h: -0.5,
        realtimeStatus: const RealtimeStatus.offline(),
        isStale: false,
        chartLoading: false,
        isWatchlisted: false,
        chartFailure: const NetworkFailure(offline: true),
      ),
    );
    when(() => bloc.add(any())).thenReturn(null);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    await tester.tap(find.text('Try again'));
    await tester.pump();

    verify(
      () => bloc.add(const CoinDetailChartRangeChanged(ChartPeriod.oneDay)),
    ).called(1);
  });

  testWidgets('watchlist star dispatches toggle', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(binanceSymbol: 'BTCUSDT'),
    );
    when(() => bloc.add(any())).thenReturn(null);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();

    verify(() => bloc.add(const CoinDetailWatchlistToggled())).called(1);
  });

  testWidgets('shows chart empty message for sparse series', (tester) async {
    whenListen(
      bloc,
      const Stream<CoinDetailState>.empty(),
      initialState: _loadedState(binanceSymbol: 'BTCUSDT').copyWith(
        chart: PriceChartSeries(
          points: [ChartPoint(timestamp: DateTime.utc(2026), priceEur: 20)],
          range: ChartPeriod.oneDay,
          source: ChartDataSource.coinGeckoMarketChart,
          fetchedAt: DateTime.utc(2026),
        ),
      ),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.text('Not enough chart data for this range.'), findsOneWidget);
  });
}
