import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/bloc/coin_detail_bloc.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/coin_detail/watchlist/watchlist_toggle.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

import '../../core/realtime/fake_price_stream_service.dart';

class MockCoinDetailRepository extends Mock implements CoinDetailRepository {}

class MockWatchlistToggle extends Mock implements WatchlistToggle {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _RecordingCoordinator extends RealtimeSubscriptionCoordinator {
  _RecordingCoordinator() : super(_NoopPriceStream());

  final List<String> removedTokens = [];
  String? lastToken;
  Set<String>? lastSymbols;

  @override
  void setSymbols(String token, Set<String> lowercaseBinanceSymbols) {
    lastToken = token;
    lastSymbols = lowercaseBinanceSymbols;
    super.setSymbols(token, lowercaseBinanceSymbols);
  }

  @override
  void removeToken(String token) {
    removedTokens.add(token);
    super.removeToken(token);
  }
}

class _NoopPriceStream implements PriceStreamService {
  _NoopPriceStream();

  final RealtimeStatus _status = const RealtimeStatus.offline();

  @override
  RealtimeStatus get currentStatus => _status;

  @override
  Stream<PriceTick> get ticks => const Stream.empty();

  @override
  Stream<RealtimeStatus> get status => const Stream.empty();

  @override
  void setDesiredSymbols(Set<String> lowercaseBinanceSymbols) {}

  @override
  void setAppLifecycle(AppLifecycleState state) {}

  @override
  Future<void> dispose() async {}
}

CoinDetail _detail() {
  return CoinDetail(
    id: 'bitcoin',
    symbol: 'BTC',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 65000,
    priceChangePercent24h: 1,
    marketCapEur: 1,
    volume24hEur: 1,
    high24hEur: 1,
    low24hEur: 1,
    circulatingSupply: 1,
    athEur: 1,
    aboutTextEn: 'About',
    fetchedAt: DateTime.utc(2026),
    binanceSymbol: 'BTCUSDT',
  );
}

PriceChartSeries _chart(ChartPeriod range) {
  return PriceChartSeries(
    points: [
      ChartPoint(timestamp: DateTime.utc(2026), priceEur: 64000),
      ChartPoint(timestamp: DateTime.utc(2026, 1, 2), priceEur: 65000),
    ],
    range: range,
    source: ChartDataSource.binanceKlines,
    fetchedAt: DateTime.utc(2026, 1, 2),
  );
}

void main() {
  late MockCoinDetailRepository repository;
  late FakePriceStreamService priceStream;
  late _RecordingCoordinator coordinator;
  late MockWatchlistToggle watchlistToggle;
  late MockSettingsRepository settingsRepository;

  setUpAll(() {
    registerFallbackValue(ChartPeriod.oneDay);
    registerFallbackValue('bitcoin');
  });

  setUp(() {
    repository = MockCoinDetailRepository();
    priceStream = FakePriceStreamService();
    coordinator = _RecordingCoordinator();
    watchlistToggle = MockWatchlistToggle();
    settingsRepository = MockSettingsRepository();
    when(() => settingsRepository.current).thenReturn(UserPreferences.defaults);
    when(
      () => settingsRepository.changes,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => watchlistToggle.isWatched('bitcoin'),
    ).thenAnswer((_) async => false);
    when(
      () => watchlistToggle.isWatched('missing'),
    ).thenAnswer((_) async => false);
    when(
      () => watchlistToggle.setWatched(any(), watched: any(named: 'watched')),
    ).thenAnswer((_) async {});
  });

  CoinDetailBloc buildBloc() {
    return CoinDetailBloc(
      repository: repository,
      subscriptionCoordinator: coordinator,
      priceStreamService: priceStream,
      watchlistToggle: watchlistToggle,
      settingsRepository: settingsRepository,
    );
  }

  blocTest<CoinDetailBloc, CoinDetailState>(
    'loads detail and registers live subscription token',
    build: buildBloc,
    setUp: () {
      when(
        () => repository.loadDetail('bitcoin'),
      ).thenAnswer((_) async => Success(_detail()));
      when(
        () => repository.loadChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneDay,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneDay)));
    },
    act: (bloc) => bloc.add(const CoinDetailStarted('bitcoin')),
    expect: () => [
      isA<CoinDetailState>().having(
        (s) => s.status,
        'status',
        CoinDetailStatus.loading,
      ),
      isA<CoinDetailState>()
          .having((s) => s.status, 'status', CoinDetailStatus.loaded)
          .having((s) => s.livePriceEur, 'price', 65000),
    ],
    verify: (_) {
      expect(coordinator.lastToken, 'coin_detail:bitcoin');
      expect(coordinator.lastSymbols, {'btcusdt'});
    },
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'merges live tick into state',
    build: buildBloc,
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.live(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    act: (bloc) => bloc.add(
      CoinDetailPriceTickReceived(
        PriceTick(
          symbol: 'BTCUSDT',
          lastPriceUsdt: 70000,
          lastPriceEur: 65500,
          changePercent24h: 2.5,
          eventTime: DateTime.utc(2026, 1, 3),
        ),
      ),
    ),
    expect: () => [
      isA<CoinDetailState>()
          .having((s) => s.livePriceEur, 'price', 65500)
          .having((s) => s.changePercent24h, 'change', 2.5),
    ],
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'chart range change uses restartable load',
    build: buildBloc,
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.offline(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    setUp: () {
      when(
        () => repository.loadChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneWeek,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneWeek)));
    },
    act: (bloc) =>
        bloc.add(const CoinDetailChartRangeChanged(ChartPeriod.oneWeek)),
    expect: () => [
      isA<CoinDetailState>().having((s) => s.chartLoading, 'loading', isTrue),
      isA<CoinDetailState>()
          .having((s) => s.selectedRange, 'range', ChartPeriod.oneWeek)
          .having((s) => s.chartLoading, 'loading', isFalse),
    ],
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'retry uses refreshDetail and refreshChart',
    build: buildBloc,
    seed: () => CoinDetailState.failure(
      coinId: 'bitcoin',
      failure: const NetworkFailure(offline: true),
    ),
    setUp: () {
      when(
        () => repository.refreshDetail('bitcoin'),
      ).thenAnswer((_) async => Success(_detail()));
      when(
        () => repository.refreshChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneDay,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneDay)));
    },
    act: (bloc) => bloc.add(const CoinDetailRetryRequested()),
    verify: (_) {
      verify(() => repository.refreshDetail('bitcoin')).called(1);
      verifyNever(() => repository.loadDetail('bitcoin'));
      verify(
        () => repository.refreshChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneDay,
          binanceSymbol: 'BTCUSDT',
        ),
      ).called(1);
    },
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'seeds connecting status when live feed expected and service offline',
    build: buildBloc,
    setUp: () {
      priceStream.emitStatus(const RealtimeStatus.offline());
      when(
        () => repository.loadDetail('bitcoin'),
      ).thenAnswer((_) async => Success(_detail()));
      when(
        () => repository.loadChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneDay,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneDay)));
    },
    act: (bloc) => bloc.add(const CoinDetailStarted('bitcoin')),
    expect: () => [
      isA<CoinDetailState>().having(
        (s) => s.status,
        'status',
        CoinDetailStatus.loading,
      ),
      isA<CoinDetailState>().having(
        (s) => s.realtimeStatus,
        'status',
        isA<RealtimeConnecting>(),
      ),
    ],
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'restartable range change keeps last completed range',
    build: buildBloc,
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.offline(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    setUp: () {
      final slowWeek = Completer<Result<PriceChartSeries>>();
      when(
        () => repository.loadChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneWeek,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) => slowWeek.future);
      when(
        () => repository.loadChart(
          coinId: 'bitcoin',
          range: ChartPeriod.oneDay,
          binanceSymbol: 'BTCUSDT',
        ),
      ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneDay)));
    },
    act: (bloc) async {
      bloc.add(const CoinDetailChartRangeChanged(ChartPeriod.oneWeek));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CoinDetailChartRangeChanged(ChartPeriod.oneDay));
    },
    expect: () => [
      isA<CoinDetailState>().having((s) => s.chartLoading, 'loading', isTrue),
      isA<CoinDetailState>().having((s) => s.chartLoading, 'loading', isTrue),
      isA<CoinDetailState>()
          .having((s) => s.selectedRange, 'range', ChartPeriod.oneDay)
          .having((s) => s.chart?.range, 'chart', ChartPeriod.oneDay),
    ],
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'failure when detail cannot load',
    build: buildBloc,
    setUp: () {
      when(
        () => repository.loadDetail('missing'),
      ).thenAnswer((_) async => const Failure(NotFoundFailure()));
    },
    act: (bloc) => bloc.add(const CoinDetailStarted('missing')),
    expect: () => [
      isA<CoinDetailState>().having(
        (s) => s.status,
        'status',
        CoinDetailStatus.loading,
      ),
      isA<CoinDetailState>().having(
        (s) => s.status,
        'status',
        CoinDetailStatus.failure,
      ),
    ],
    verify: (_) {
      verifyNever(
        () => repository.loadChart(
          coinId: any(named: 'coinId'),
          range: any(named: 'range'),
          binanceSymbol: any(named: 'binanceSymbol'),
        ),
      );
    },
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'watchlist toggle updates state',
    build: buildBloc,
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.offline(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    act: (bloc) => bloc.add(const CoinDetailWatchlistToggled()),
    expect: () => [
      isA<CoinDetailState>().having(
        (s) => s.isWatchlisted,
        'watchlisted',
        isTrue,
      ),
    ],
    verify: (_) {
      verify(
        () => watchlistToggle.setWatched('bitcoin', watched: true),
      ).called(1);
    },
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'live tick uses USDT when display currency is USD',
    build: () {
      when(() => settingsRepository.current).thenReturn(
        UserPreferences.defaults.copyWith(displayCurrency: DisplayCurrency.usd),
      );
      return buildBloc();
    },
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.live(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    act: (bloc) => bloc.add(
      CoinDetailPriceTickReceived(
        PriceTick(
          symbol: 'BTCUSDT',
          lastPriceUsdt: 70000,
          lastPriceEur: 65500,
          changePercent24h: 2.5,
          eventTime: DateTime.utc(2026, 1, 3),
        ),
      ),
    ),
    expect: () => [
      isA<CoinDetailState>().having((s) => s.livePriceEur, 'price', 70000),
    ],
  );

  blocTest<CoinDetailBloc, CoinDetailState>(
    'forwards live status to state',
    build: buildBloc,
    seed: () => CoinDetailState.loaded(
      coinId: 'bitcoin',
      detail: _detail(),
      chart: _chart(ChartPeriod.oneDay),
      selectedRange: ChartPeriod.oneDay,
      livePriceEur: 65000,
      changePercent24h: 1,
      realtimeStatus: const RealtimeStatus.connecting(),
      isStale: false,
      chartLoading: false,
      isWatchlisted: false,
    ),
    act: (bloc) =>
        bloc.add(const CoinDetailRealtimeStatusChanged(RealtimeStatus.live())),
    expect: () => [
      isA<CoinDetailState>().having(
        (s) => s.realtimeStatus,
        'status',
        isA<RealtimeLive>(),
      ),
    ],
  );

  test('close removes subscription token', () async {
    when(
      () => repository.loadDetail('bitcoin'),
    ).thenAnswer((_) async => Success(_detail()));
    when(
      () => repository.loadChart(
        coinId: 'bitcoin',
        range: ChartPeriod.oneDay,
        binanceSymbol: 'BTCUSDT',
      ),
    ).thenAnswer((_) async => Success(_chart(ChartPeriod.oneDay)));

    final bloc = buildBloc();
    bloc.add(const CoinDetailStarted('bitcoin'));
    await bloc.stream.firstWhere((s) => s.status == CoinDetailStatus.loaded);
    await bloc.close();
    expect(coordinator.removedTokens, contains('coin_detail:bitcoin'));
  });
}
