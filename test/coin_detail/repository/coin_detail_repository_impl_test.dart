import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository_impl.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_local_data_source.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/widgets/period_selector.dart';

import '../../core/time/fake_clock.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockCoinDetailRemoteDataSource extends Mock
    implements CoinDetailRemoteDataSource {}

CoinDetail _sampleDetail(DateTime fetchedAt) {
  return CoinDetail(
    id: 'bitcoin',
    symbol: 'BTC',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 65000,
    priceChangePercent24h: 1.5,
    marketCapEur: 1e12,
    volume24hEur: 1e10,
    high24hEur: 66000,
    low24hEur: 64000,
    circulatingSupply: 19e6,
    athEur: 69000,
    aboutTextEn: 'About btc',
    fetchedAt: fetchedAt,
    binanceSymbol: 'BTCUSDT',
  );
}

PriceChartSeries _sampleChart(DateTime fetchedAt, ChartPeriod range) {
  return PriceChartSeries(
    points: [
      ChartPoint(
        timestamp: fetchedAt.subtract(const Duration(hours: 2)),
        priceEur: 64000,
      ),
      ChartPoint(timestamp: fetchedAt, priceEur: 65000),
    ],
    range: range,
    source: ChartDataSource.coinGeckoMarketChart,
    fetchedAt: fetchedAt,
  );
}

void main() {
  late Directory tempDir;
  late FakeClock clock;
  late CacheStore store;
  late CoinDetailLocalDataSource local;
  late MockConnectivityService connectivity;
  late MockCoinDetailRemoteDataSource remote;
  late CoinDetailRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_coin_detail_repo');
    clock = FakeClock(DateTime.utc(2026, 6, 1, 12));
    connectivity = MockConnectivityService();
    remote = MockCoinDetailRemoteDataSource();
    await HiveBoxes.init(path: tempDir.path);
    store = CacheStore(
      cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
      clock: clock,
    );
    local = CoinDetailLocalDataSource(cacheStore: store);
    repository = CoinDetailRepositoryImpl(
      remote: remote,
      local: local,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('loadDetail uses fresh metadata cache', () async {
    final detail = _sampleDetail(clock.now());
    await local.writeMetadata(
      cacheKey: local.metadataKeyFor(coinId: 'bitcoin'),
      detail: detail,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    final result = await repository.loadDetail('bitcoin');

    expect(result, isA<Success<CoinDetail>>());
    verifyNever(() => remote.fetchDetail(any()));
  });

  test('loadChart uses TTL key per range', () async {
    final chart = _sampleChart(clock.now(), ChartPeriod.oneWeek);
    await local.writeChart(
      cacheKey: local.chartKeyFor(
        coinId: 'bitcoin',
        range: ChartPeriod.oneWeek,
      ),
      series: chart,
      range: ChartPeriod.oneWeek,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    final result = await repository.loadChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneWeek,
    );

    expect(result, isA<Success<PriceChartSeries>>());
    verifyZeroInteractions(remote);
  });

  test('loadChart fetches remote on miss with binance symbol', () async {
    final detail = _sampleDetail(clock.now());
    final chart = _sampleChart(clock.now(), ChartPeriod.oneDay);
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => remote.fetchDetail('bitcoin'),
    ).thenAnswer((_) async => Success(detail));
    when(
      () => remote.fetchChart(
        coinId: 'bitcoin',
        range: ChartPeriod.oneDay,
        binanceSymbol: 'BTCUSDT',
      ),
    ).thenAnswer((_) async => Success(chart));

    final result = await repository.loadChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneDay,
    );

    expect(result, isA<Success<PriceChartSeries>>());
    verify(
      () => remote.fetchChart(
        coinId: 'bitcoin',
        range: ChartPeriod.oneDay,
        binanceSymbol: 'BTCUSDT',
      ),
    ).called(1);
  });

  test('loadChart offline returns stale envelope', () async {
    final chart = _sampleChart(clock.now(), ChartPeriod.oneDay);
    await local.writeChart(
      cacheKey: local.chartKeyFor(coinId: 'bitcoin', range: ChartPeriod.oneDay),
      series: chart,
      range: ChartPeriod.oneDay,
    );
    clock.advance(const Duration(minutes: 10));
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await repository.loadChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneDay,
    );

    expect(result, isA<Success<PriceChartSeries>>());
    expect((result as Success).isStale, isTrue);
  });

  test('loadDetail returns failure when offline without cache', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await repository.loadDetail('unknown');

    expect(result, isA<Failure<CoinDetail>>());
    expect((result as Failure).error, isA<NetworkFailure>());
  });
}
