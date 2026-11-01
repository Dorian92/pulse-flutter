import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';
import '../../core/realtime/fake_price_stream_service.dart';

class MockMarketsRepository extends Mock implements MarketsRepository {}

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockMarketsRepository repository;
  late FakePriceStreamService fakeStream;
  late RealtimeSubscriptionCoordinator coordinator;
  late SymbolMapper mapper;

  const btc = MarketCoin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 100,
    priceChangePercent24h: 1,
    marketCapRank: 1,
    sparkline7d: [1],
    binanceSymbol: 'BTCUSDT',
  );

  const unmapped = MarketCoin(
    id: 'obscure',
    symbol: 'obs',
    name: 'Obscure',
    imageUrl: '',
    currentPriceEur: 1,
    priceChangePercent24h: 0,
    marketCapRank: 50,
    sparkline7d: [1],
  );

  final snapshot = MarketsSnapshot(
    fetchedAt: DateTime.utc(2026, 6),
    global: const GlobalMarketSummary(
      totalMarketCapEur: 1,
      marketCapChangePercent24h: 0,
    ),
    coins: const [btc, unmapped],
  );

  setUp(() {
    repository = MockMarketsRepository();
    fakeStream = FakePriceStreamService();
    coordinator = RealtimeSubscriptionCoordinator(fakeStream);
    mapper = SymbolMapper();
    when(
      () => repository.loadMarkets(),
    ).thenAnswer((_) async => Success(snapshot));
  });

  MarketsBloc buildBloc() {
    final watchlist = MockWatchlistRepository();
    final settings = MockSettingsRepository();
    when(() => watchlist.getOrderedIds()).thenAnswer((_) async => []);
    when(
      () => watchlist.membershipChanges,
    ).thenAnswer((_) => const Stream<void>.empty());
    when(() => settings.current).thenReturn(UserPreferences.defaults);
    when(() => settings.changes).thenAnswer((_) => const Stream.empty());
    return MarketsBloc(
      repository: repository,
      subscriptionCoordinator: coordinator,
      priceStreamService: fakeStream,
      symbolMapper: mapper,
      watchlistRepository: watchlist,
      settingsRepository: settings,
    );
  }

  blocTest<MarketsBloc, MarketsState>(
    'registers top binance symbols after load',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const MarketsRequested());
      await bloc.stream.firstWhere(
        (state) => state.status == MarketsStatus.loaded,
      );
      expect(fakeStream.lastDesiredSymbols, {'btcusdt'});
    },
    skip: 1,
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.status,
        'status',
        MarketsStatus.loaded,
      ),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'merges live tick into snapshot and flash generation',
    build: buildBloc,
    seed: () =>
        MarketsState.loaded(snapshot: snapshot, visibleCoins: const [btc]),
    act: (bloc) async {
      bloc.add(
        MarketsPriceTickReceived(
          PriceTick(
            symbol: 'BTCUSDT',
            lastPriceUsdt: 105,
            lastPriceEur: 105,
            changePercent24h: 2.5,
            eventTime: DateTime.utc(2026, 6, 1, 12, 1),
          ),
        ),
      );
    },
    expect: () => [
      isA<MarketsState>()
          .having((s) => s.snapshot!.coins.first.currentPriceEur, 'price', 105)
          .having((s) => s.liveFlashGeneration, 'flashGen', 1)
          .having((s) => s.liveFlashCoinId, 'flashCoin', 'bitcoin'),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'forwards realtime status to state',
    build: buildBloc,
    act: (bloc) async {
      fakeStream.emitStatus(const RealtimeStatus.live());
    },
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.realtimeStatus,
        'status',
        isA<RealtimeLive>(),
      ),
    ],
  );

  blocTest<MarketsBloc, MarketsState>(
    'remaps binance symbols when SymbolMapper updates',
    build: buildBloc,
    seed: () => MarketsState.loaded(
      snapshot: snapshot,
      visibleCoins: const [btc, unmapped],
    ),
    act: (bloc) async {
      mapper.applyExchangeBaseAssets({'OBS': 'OBSUSDT'});
      await bloc.stream.firstWhere(
        (s) => s.visibleCoins.any((c) => c.id == 'obscure' && c.hasLiveFeed),
      );
      expect(fakeStream.lastDesiredSymbols, contains('obsusdt'));
    },
    expect: () => [
      isA<MarketsState>().having(
        (s) => s.visibleCoins.last.binanceSymbol,
        'mapped',
        'OBSUSDT',
      ),
    ],
  );
}
