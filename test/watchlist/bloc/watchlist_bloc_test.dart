import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/bloc/watchlist_bloc.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';
import '../../core/realtime/fake_price_stream_service.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockWatchlistRepository repository;
  late MockSettingsRepository settings;
  late FakePriceStreamService fakeStream;

  const coin = MarketCoin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 100,
    priceChangePercent24h: 1,
    marketCapRank: 1,
    sparkline7d: [1, 2],
    binanceSymbol: 'BTCUSDT',
  );

  WatchlistBloc buildBloc() {
    final coordinator = RealtimeSubscriptionCoordinator(fakeStream);
    return WatchlistBloc(
      repository: repository,
      subscriptionCoordinator: coordinator,
      priceStreamService: fakeStream,
      symbolMapper: SymbolMapper(),
      settingsRepository: settings,
    );
  }

  setUp(() {
    repository = MockWatchlistRepository();
    settings = MockSettingsRepository();
    fakeStream = FakePriceStreamService();
    when(() => settings.current).thenReturn(UserPreferences.defaults);
    when(() => settings.changes).thenAnswer((_) => const Stream.empty());
  });

  blocTest<WatchlistBloc, WatchlistState>(
    'loads watchlist coins',
    build: () {
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(
          WatchlistSnapshot(
            coins: const [coin],
            fetchedAt: DateTime.utc(2026, 6),
          ),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const WatchlistRequested()),
    expect: () => [
      isA<WatchlistState>().having(
        (s) => s.status,
        'status',
        WatchlistStatus.loading,
      ),
      isA<WatchlistState>()
          .having((s) => s.status, 'status', WatchlistStatus.loaded)
          .having((s) => s.coins.length, 'coins', 1),
    ],
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'remove sets pending undo payload',
    build: () {
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(
          WatchlistSnapshot(
            coins: const [coin],
            fetchedAt: DateTime.utc(2026, 6),
          ),
        ),
      );
      when(
        () => repository.setWatched('bitcoin', watched: false),
      ).thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const WatchlistRequested());
      await bloc.stream.firstWhere((s) => s.status == WatchlistStatus.loaded);
      bloc.add(const WatchlistRemoveRequested('bitcoin'));
    },
    expect: () => [
      isA<WatchlistState>(),
      isA<WatchlistState>(),
      isA<WatchlistState>()
          .having((s) => s.coins, 'coins', isEmpty)
          .having((s) => s.pendingUndo?.coinId, 'undo', 'bitcoin'),
    ],
  );

  test('close removes watchlist subscription token', () async {
    when(
      () => repository.loadWatchlist(),
    ).thenAnswer((_) async => const Success(WatchlistSnapshot(coins: [coin])));
    final coordinator = RealtimeSubscriptionCoordinator(fakeStream);
    final bloc = WatchlistBloc(
      repository: repository,
      subscriptionCoordinator: coordinator,
      priceStreamService: fakeStream,
      symbolMapper: SymbolMapper(),
      settingsRepository: settings,
    );
    bloc.add(const WatchlistRequested());
    await bloc.stream.firstWhere((s) => s.status == WatchlistStatus.loaded);
    expect(fakeStream.lastDesiredSymbols, {'btcusdt'});
    await bloc.close();
    expect(fakeStream.lastDesiredSymbols, isEmpty);
  });
}
