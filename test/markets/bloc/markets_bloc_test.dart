import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import '../../core/realtime/fake_price_stream_service.dart';

class MockMarketsRepository extends Mock implements MarketsRepository {}

MarketsBloc _buildBloc(MockMarketsRepository repository) {
  final fakeStream = FakePriceStreamService();
  final coordinator = RealtimeSubscriptionCoordinator(fakeStream);
  return MarketsBloc(
    repository: repository,
    subscriptionCoordinator: coordinator,
    priceStreamService: fakeStream,
  );
}

MarketsSnapshot _snapshot() {
  return MarketsSnapshot(
    fetchedAt: DateTime.utc(2026, 6, 1, 12),
    global: const GlobalMarketSummary(
      totalMarketCapEur: 100,
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
        sparkline7d: [1, 2, 3],
      ),
      MarketCoin(
        id: 'loser',
        symbol: 'lsr',
        name: 'Loser Coin',
        imageUrl: '',
        currentPriceEur: 1,
        priceChangePercent24h: -5,
        marketCapRank: 2,
        sparkline7d: [1],
      ),
    ],
  );
}

void main() {
  late MockMarketsRepository repository;

  setUp(() {
    repository = MockMarketsRepository();
  });

  blocTest<MarketsBloc, MarketsState>(
    'loads markets on request',
    build: () {
      when(
        () => repository.loadMarkets(),
      ).thenAnswer((_) async => Success(_snapshot()));
      return _buildBloc(repository);
    },
    act: (bloc) => bloc.add(const MarketsRequested()),
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.loading,
      ),
      isA<MarketsState>()
          .having((s) => s.status, 'status', MarketsStatus.loaded)
          .having((s) => s.visibleCoins, 'coins', hasLength(2)),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'emits failure when load fails without cache',
    build: () {
      when(
        () => repository.loadMarkets(),
      ).thenAnswer((_) async => const Failure(NetworkFailure(offline: true)));
      return _buildBloc(repository);
    },
    act: (bloc) => bloc.add(const MarketsRequested()),
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.loading,
      ),
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.failure,
      ),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'filters gainers client-side',
    build: () {
      when(
        () => repository.loadMarkets(),
      ).thenAnswer((_) async => Success(_snapshot()));
      return _buildBloc(repository);
    },
    act: (bloc) async {
      bloc.add(const MarketsRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const MarketsFilterChanged(MarketFilter.gainers));
    },
    skip: 1,
    verify: (bloc) {
      expect(bloc.state.visibleCoins, hasLength(1));
      expect(bloc.state.visibleCoins.first.id, 'bitcoin');
    },
  );

  blocTest<MarketsBloc, MarketsState>(
    'search narrows visible coins',
    build: () {
      when(
        () => repository.loadMarkets(),
      ).thenAnswer((_) async => Success(_snapshot()));
      return _buildBloc(repository);
    },
    seed: () => MarketsState.loaded(
      snapshot: _snapshot(),
      visibleCoins: _snapshot().coins,
    ),
    act: (bloc) => bloc.add(const MarketsSearchQueryChanged('loser')),
    expect: () => [
      isA<MarketsState>()
          .having((s) => s.visibleCoins, 'visible', hasLength(1))
          .having((s) => s.visibleCoins.first.id, 'id', 'loser'),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'refresh stale success exposes repository refreshError',
    build: () {
      when(() => repository.refreshMarkets()).thenAnswer(
        (_) async => Success(
          _snapshot(),
          isStale: true,
          refreshError: const RateLimitFailure(retryAfterSeconds: 12),
        ),
      );
      return _buildBloc(repository);
    },
    seed: () => MarketsState.loaded(
      snapshot: _snapshot(),
      visibleCoins: _snapshot().coins,
    ),
    act: (bloc) => bloc.add(const MarketsRefreshRequested()),
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.loading,
      ),
      isA<MarketsState>()
          .having((s) => s.isStale, 'stale', isTrue)
          .having(
            (s) => s.refreshFailure,
            'refreshFailure',
            isA<RateLimitFailure>(),
          ),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'refresh failure with existing data sets refreshFailure',
    build: () {
      when(
        () => repository.refreshMarkets(),
      ).thenAnswer((_) async => const Failure(ServerFailure(statusCode: 503)));
      return _buildBloc(repository);
    },
    seed: () => MarketsState.loaded(
      snapshot: _snapshot(),
      visibleCoins: _snapshot().coins,
    ),
    act: (bloc) => bloc.add(const MarketsRefreshRequested()),
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.loading,
      ),
      isA<MarketsState>().having(
        (s) => s.refreshFailure,
        'refreshFailure',
        isA<ServerFailure>(),
      ),
    ],
  );
}
