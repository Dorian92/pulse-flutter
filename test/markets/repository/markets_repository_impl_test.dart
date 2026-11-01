import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/data_sources/markets_local_data_source.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';
import 'package:pulse/markets/repository/markets_repository_impl.dart';

import '../../core/time/fake_clock.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockMarketsRemoteDataSource extends Mock
    implements MarketsRemoteDataSource {}

MarketsSnapshot _sampleSnapshot(DateTime fetchedAt) {
  return MarketsSnapshot(
    fetchedAt: fetchedAt,
    global: const GlobalMarketSummary(
      totalMarketCapEur: 1000,
      marketCapChangePercent24h: 1,
    ),
    coins: const [
      MarketCoin(
        id: 'bitcoin',
        symbol: 'btc',
        name: 'Bitcoin',
        imageUrl: '',
        currentPriceEur: 1,
        priceChangePercent24h: 2,
        marketCapRank: 1,
        sparkline7d: [1, 2],
        binanceSymbol: 'BTCUSDT',
      ),
    ],
  );
}

void main() {
  late Directory tempDir;
  late FakeClock clock;
  late CacheStore store;
  late MarketsLocalDataSource local;
  late MockConnectivityService connectivity;
  late MockMarketsRemoteDataSource remote;
  late MarketsRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_markets_repo');
    clock = FakeClock(DateTime.utc(2026, 6, 1, 12));
    connectivity = MockConnectivityService();
    remote = MockMarketsRemoteDataSource();
    await HiveBoxes.init(path: tempDir.path);
    store = CacheStore(
      cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
      clock: clock,
    );
    local = MarketsLocalDataSource(cacheStore: store);
    repository = MarketsRepositoryImpl(
      remote: remote,
      local: local,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('loadMarkets returns fresh cache without remote call', () async {
    final snapshot = _sampleSnapshot(clock.now());
    await local.writeSnapshot(cacheKey: 'markets:eur', snapshot: snapshot);
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    final result = await repository.loadMarkets();

    expect(result, isA<Success<MarketsSnapshot>>());
    expect((result as Success).isStale, isFalse);
    verifyNever(() => remote.fetchMarkets());
  });

  test('loadMarkets offline serves stale cache', () async {
    final snapshot = _sampleSnapshot(clock.now());
    await local.writeSnapshot(cacheKey: 'markets:eur', snapshot: snapshot);
    clock.advance(const Duration(minutes: 20));
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await repository.loadMarkets();

    expect(result, isA<Success<MarketsSnapshot>>());
    expect((result as Success).isStale, isTrue);
  });

  test('loadMarkets fetches remote on cache miss', () async {
    final snapshot = _sampleSnapshot(clock.now());
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => remote.fetchMarkets(),
    ).thenAnswer((_) async => Success(snapshot));

    final result = await repository.loadMarkets();

    expect(result, isA<Success<MarketsSnapshot>>());
    verify(() => remote.fetchMarkets()).called(1);
    final cached = await local.readFreshJson('markets:eur');
    expect(cached, isNotNull);
  });

  test('loadMarkets returns stale when remote fails', () async {
    final snapshot = _sampleSnapshot(clock.now());
    await local.writeSnapshot(cacheKey: 'markets:eur', snapshot: snapshot);
    clock.advance(const Duration(minutes: 20));
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => remote.fetchMarkets(),
    ).thenAnswer((_) async => const Failure(NetworkFailure()));

    final result = await repository.loadMarkets();

    expect(result, isA<Success<MarketsSnapshot>>());
    expect((result as Success).isStale, isTrue);
  });

  test('loadMarkets fails when remote fails and no cache', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => remote.fetchMarkets(),
    ).thenAnswer((_) async => const Failure(ServerFailure(statusCode: 500)));

    final result = await repository.loadMarkets();

    expect(result, isA<Failure<MarketsSnapshot>>());
  });

  test('refreshMarkets bypasses fresh cache TTL', () async {
    final cached = _sampleSnapshot(clock.now());
    final remoteSnapshot = _sampleSnapshot(
      clock.now().add(const Duration(hours: 1)),
    );
    await local.writeSnapshot(cacheKey: 'markets:eur', snapshot: cached);
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => remote.fetchMarkets(),
    ).thenAnswer((_) async => Success(remoteSnapshot));

    final result = await repository.refreshMarkets();

    expect(result, isA<Success<MarketsSnapshot>>());
    verify(() => remote.fetchMarkets()).called(1);
  });
}
