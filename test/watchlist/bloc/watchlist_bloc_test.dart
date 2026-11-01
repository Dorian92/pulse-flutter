import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/models/display_currency.dart';
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
  late StreamController<void> membershipController;

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

  WatchlistSnapshot snapshotWithCoin(DateTime fetchedAt) {
    return WatchlistSnapshot(
      entries: [const WatchlistEntry(coinId: 'bitcoin', coin: coin)],
      fetchedAt: fetchedAt,
    );
  }

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
    when(
      () => repository.membershipChanges,
    ).thenAnswer((_) => const Stream<void>.empty());
  });

  blocTest<WatchlistBloc, WatchlistState>(
    'loads watchlist coins',
    build: () {
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))),
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
        (_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))),
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
          .having((s) => s.entries, 'entries', isEmpty)
          .having((s) => s.pendingUndo?.coinId, 'undo', 'bitcoin'),
    ],
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'undo restore reinserts entry',
    build: () {
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))),
      );
      when(
        () => repository.setWatched('bitcoin', watched: false),
      ).thenAnswer((_) async {});
      when(
        () => repository.insertAt(coinId: 'bitcoin', index: 0),
      ).thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const WatchlistRequested());
      await bloc.stream.firstWhere((s) => s.status == WatchlistStatus.loaded);
      bloc.add(const WatchlistRemoveRequested('bitcoin'));
      await bloc.stream.firstWhere((s) => s.pendingUndo != null);
      bloc.add(const WatchlistUndoRemoveRequested());
    },
    verify: (_) {
      verify(() => repository.insertAt(coinId: 'bitcoin', index: 0)).called(1);
    },
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'merges live tick with USD display currency',
    build: () {
      when(() => settings.current).thenReturn(
        UserPreferences.defaults.copyWith(displayCurrency: DisplayCurrency.usd),
      );
      return buildBloc();
    },
    seed: () => const WatchlistState(
      status: WatchlistStatus.loaded,
      entries: [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
      isStale: false,
      isEditing: false,
      realtimeStatus: RealtimeStatus.live(),
    ),
    act: (bloc) => bloc.add(
      WatchlistPriceTickReceived(
        PriceTick(
          symbol: 'BTCUSDT',
          lastPriceUsdt: 42000,
          lastPriceEur: 39000,
          changePercent24h: 2,
          eventTime: DateTime.utc(2026),
        ),
      ),
    ),
    expect: () => [
      isA<WatchlistState>().having(
        (s) => s.entries.first.coin?.currentPriceEur,
        'price',
        42000,
      ),
    ],
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'membership change reloads watchlist',
    build: () {
      membershipController = StreamController<void>.broadcast();
      when(
        () => repository.membershipChanges,
      ).thenAnswer((_) => membershipController.stream);
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))),
      );
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const WatchlistRequested());
      await bloc.stream.firstWhere((s) => s.status == WatchlistStatus.loaded);
      membershipController.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    tearDown: () async {
      await membershipController.close();
    },
    verify: (_) {
      verify(() => repository.loadWatchlist()).called(2);
    },
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'refresh failure keeps entries with refreshFailure',
    build: () {
      when(() => repository.loadWatchlist()).thenAnswer(
        (_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))),
      );
      when(() => repository.refreshWatchlist()).thenAnswer(
        (_) async => Success(
          snapshotWithCoin(DateTime.utc(2026, 6)),
          isStale: true,
          refreshError: const ServerFailure(statusCode: 503),
        ),
      );
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const WatchlistRequested());
      await bloc.stream.firstWhere((s) => s.status == WatchlistStatus.loaded);
      bloc.add(const WatchlistRefreshRequested());
    },
    verify: (bloc) {
      expect(bloc.state.refreshFailure, isA<ServerFailure>());
      expect(bloc.state.isStale, isTrue);
    },
  );

  test('close removes watchlist subscription token', () async {
    when(
      () => repository.loadWatchlist(),
    ).thenAnswer((_) async => Success(snapshotWithCoin(DateTime.utc(2026, 6))));
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
