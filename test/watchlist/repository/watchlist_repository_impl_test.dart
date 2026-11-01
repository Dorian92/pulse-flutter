import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_local_data_source.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_markets_data_source.dart';
import 'package:pulse/watchlist/repository/watchlist_repository_impl.dart';

class MockWatchlistLocalDataSource extends Mock
    implements WatchlistLocalDataSource {}

class MockMarketsRepository extends Mock implements MarketsRepository {}

class MockWatchlistMarketsDataSource extends Mock
    implements WatchlistMarketsDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockWatchlistLocalDataSource local;
  late MockMarketsRepository markets;
  late MockWatchlistMarketsDataSource supplemental;
  late MockConnectivityService connectivity;
  late WatchlistRepositoryImpl repository;

  const bitcoin = MarketCoin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 1,
    priceChangePercent24h: 1,
    marketCapRank: 1,
    sparkline7d: const [1],
  );

  const chainlink = MarketCoin(
    id: 'chainlink',
    symbol: 'link',
    name: 'Chainlink',
    imageUrl: '',
    currentPriceEur: 2,
    priceChangePercent24h: -1,
    marketCapRank: 20,
    sparkline7d: const [1, 2],
  );

  setUp(() {
    local = MockWatchlistLocalDataSource();
    markets = MockMarketsRepository();
    supplemental = MockWatchlistMarketsDataSource();
    connectivity = MockConnectivityService();
    repository = WatchlistRepositoryImpl(
      local: local,
      marketsRepository: markets,
      supplementalMarkets: supplemental,
      connectivity: connectivity,
    );
  });

  test(
    'merges top-100 rows with supplemental fetch preserving order',
    () async {
      when(
        () => local.readOrderedIds(),
      ).thenAnswer((_) async => ['chainlink', 'bitcoin']);
      when(() => markets.loadMarkets()).thenAnswer(
        (_) async => Success(
          MarketsSnapshot(
            fetchedAt: DateTime.utc(2026, 6, 1),
            global: const GlobalMarketSummary(marketCapChangePercent24h: 0),
            coins: const [bitcoin],
          ),
        ),
      );
      when(
        () => supplemental.fetchByIds(['chainlink']),
      ).thenAnswer((_) async => const Success([chainlink]));

      final result = await repository.loadWatchlist();

      expect(result, isA<Success<WatchlistSnapshot>>());
      final snapshot = (result as Success).value as WatchlistSnapshot;
      expect(snapshot.entries.map((e) => e.coinId), ['chainlink', 'bitcoin']);
      expect(snapshot.entries.first.coin?.symbol, 'link');
    },
  );

  test('missing supplemental row yields unavailable placeholder', () async {
    when(
      () => local.readOrderedIds(),
    ).thenAnswer((_) async => ['ghostcoin', 'bitcoin']);
    when(() => markets.loadMarkets()).thenAnswer(
      (_) async => Success(
        MarketsSnapshot(
          fetchedAt: DateTime.utc(2026, 6, 1),
          global: const GlobalMarketSummary(marketCapChangePercent24h: 0),
          coins: const [bitcoin],
        ),
      ),
    );
    when(
      () => supplemental.fetchByIds(['ghostcoin']),
    ).thenAnswer((_) async => const Success([]));

    final result = await repository.loadWatchlist();
    final entries = (result as Success).value.entries;
    expect(entries.first.isUnavailable, isTrue);
    expect(entries.first.coinId, 'ghostcoin');
    expect(entries.last.coin?.id, 'bitcoin');
  });

  test('supplemental stale surfaces isStale on snapshot', () async {
    when(() => local.readOrderedIds()).thenAnswer((_) async => ['chainlink']);
    when(() => markets.loadMarkets()).thenAnswer(
      (_) async => Success(
        MarketsSnapshot(
          fetchedAt: DateTime.utc(2026, 6, 1),
          global: const GlobalMarketSummary(marketCapChangePercent24h: 0),
          coins: const [],
        ),
      ),
    );
    when(() => supplemental.fetchByIds(['chainlink'])).thenAnswer(
      (_) async => Success(
        const [chainlink],
        isStale: true,
        refreshError: const ServerFailure(statusCode: 503),
      ),
    );

    final result = await repository.loadWatchlist();
    expect((result as Success).isStale, isTrue);
  });

  test('setWatched emits membership change', () async {
    final changes = <void>[];
    final sub = repository.membershipChanges.listen((_) => changes.add(null));
    when(() => local.readOrderedIds()).thenAnswer((_) async => []);
    when(() => local.writeOrderedIds(['bitcoin'])).thenAnswer((_) async {});

    await repository.setWatched('bitcoin', watched: true);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(changes, hasLength(1));
  });
}
