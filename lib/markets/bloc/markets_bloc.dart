import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';

part 'markets_event.dart';
part 'markets_state.dart';

/// Manages markets list loading, refresh, search, filters, and live ticks.
class MarketsBloc extends Bloc<MarketsEvent, MarketsState> {
  /// Creates a bloc with [repository] and live dependencies.
  MarketsBloc({
    required MarketsRepository repository,
    required RealtimeSubscriptionCoordinator subscriptionCoordinator,
    required PriceStreamService priceStreamService,
    required SymbolMapper symbolMapper,
    required WatchlistRepository watchlistRepository,
    required SettingsRepository settingsRepository,
    this.maxLiveSubscriptions = 50,
  }) : _repository = repository,
       _subscriptionCoordinator = subscriptionCoordinator,
       _priceStreamService = priceStreamService,
       _symbolMapper = symbolMapper,
       _watchlistRepository = watchlistRepository,
       _settingsRepository = settingsRepository,
       super(const MarketsState.initial()) {
    on<MarketsRequested>(_onRequested);
    on<MarketsRefreshRequested>(_onRefresh, transformer: droppable());
    on<MarketsSearchQueryChanged>(_onSearchChanged, transformer: restartable());
    on<MarketsFilterChanged>(_onFilterChanged);
    on<MarketsPriceTickReceived>(_onPriceTick, transformer: sequential());
    on<MarketsRealtimeStatusChanged>(_onRealtimeStatus);
    on<MarketsSymbolMappingUpdated>(_onSymbolMappingUpdated);
    on<MarketsWatchlistToggled>(_onWatchlistToggled);
    on<MarketsPreferencesChanged>(_onPreferencesChanged);
    on<MarketsWatchlistMembershipChanged>(_onWatchlistMembershipChanged);

    _tickSubscription = _priceStreamService.ticks.listen(
      (tick) => add(MarketsPriceTickReceived(tick)),
    );
    _statusSubscription = _priceStreamService.status.listen(
      (status) => add(MarketsRealtimeStatusChanged(status)),
    );
    _mapperSubscription = _symbolMapper.updates.listen((_) {
      add(const MarketsSymbolMappingUpdated());
    });
    _settingsSubscription = _settingsRepository.changes.listen((_) {
      add(const MarketsPreferencesChanged());
    });
    _watchlistMembershipSubscription = _watchlistRepository.membershipChanges
        .listen((_) {
          add(const MarketsWatchlistMembershipChanged());
        });
  }

  static const String _marketsSubscriptionToken = 'markets';

  final MarketsRepository _repository;
  final RealtimeSubscriptionCoordinator _subscriptionCoordinator;
  final PriceStreamService _priceStreamService;
  final SymbolMapper _symbolMapper;
  final WatchlistRepository _watchlistRepository;
  final SettingsRepository _settingsRepository;

  /// Cap on Binance symbols registered from [MarketsState.visibleCoins].
  final int maxLiveSubscriptions;

  StreamSubscription<PriceTick>? _tickSubscription;
  StreamSubscription<RealtimeStatus>? _statusSubscription;
  StreamSubscription<int>? _mapperSubscription;
  StreamSubscription<UserPreferences>? _settingsSubscription;
  StreamSubscription<void>? _watchlistMembershipSubscription;
  Map<String, int> _coinIndexByBinancePair = {};

  DisplayCurrency get _displayCurrency =>
      _settingsRepository.current.displayCurrency;

  Future<Set<String>> _loadWatchedIds() async {
    final ids = await _watchlistRepository.getOrderedIds();
    return ids.toSet();
  }

  Future<void> _onRequested(
    MarketsRequested event,
    Emitter<MarketsState> emit,
  ) async {
    emit(
      MarketsState.loading(
        snapshot: state.snapshot,
        isStale: state.isStale,
        searchQuery: state.searchQuery,
        filter: state.filter,
        visibleCoins: state.visibleCoins,
        realtimeStatus: state.realtimeStatus,
      ).copyWith(clearRefreshFailure: true),
    );

    final result = await _repository.loadMarkets();
    final watchedIds = await _loadWatchedIds();
    emit(state.copyWith(watchedIds: watchedIds));
    _emitResult(result, emit, refreshAttempt: false);
  }

  Future<void> _onRefresh(
    MarketsRefreshRequested event,
    Emitter<MarketsState> emit,
  ) async {
    final previous = state;
    emit(
      MarketsState.loading(
        snapshot: previous.snapshot,
        isStale: previous.isStale,
        searchQuery: previous.searchQuery,
        filter: previous.filter,
        visibleCoins: previous.visibleCoins,
        realtimeStatus: previous.realtimeStatus,
      ),
    );

    final result = await _repository.refreshMarkets();
    _emitResult(result, emit, refreshAttempt: true);
  }

  Future<void> _onPreferencesChanged(
    MarketsPreferencesChanged event,
    Emitter<MarketsState> emit,
  ) async {
    add(const MarketsRequested());
  }

  Future<void> _onWatchlistMembershipChanged(
    MarketsWatchlistMembershipChanged event,
    Emitter<MarketsState> emit,
  ) async {
    if (state.status == MarketsStatus.initial) {
      return;
    }
    final watchedIds = await _loadWatchedIds();
    emit(state.copyWith(watchedIds: watchedIds));
    if (state.filter == MarketFilter.watchlist) {
      await _applyWatchlistFilter(emit);
      return;
    }
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return;
    }
    final visible = _applyFilters(
      coins: snapshot.coins,
      query: state.searchQuery,
      filter: state.filter,
      watchedIds: watchedIds,
    );
    emit(state.copyWith(visibleCoins: visible));
    _syncLiveSubscriptions(visible);
  }

  Future<void> _onWatchlistToggled(
    MarketsWatchlistToggled event,
    Emitter<MarketsState> emit,
  ) async {
    final watched = state.watchedIds.contains(event.coinId);
    await _watchlistRepository.setWatched(event.coinId, watched: !watched);
    final nextIds = Set<String>.from(state.watchedIds);
    if (watched) {
      nextIds.remove(event.coinId);
    } else {
      nextIds.add(event.coinId);
    }
    emit(state.copyWith(watchedIds: nextIds));
    if (state.filter == MarketFilter.watchlist) {
      await _applyWatchlistFilter(emit);
    }
  }

  void _onSearchChanged(
    MarketsSearchQueryChanged event,
    Emitter<MarketsState> emit,
  ) {
    if (state.filter == MarketFilter.watchlist) {
      emit(state.copyWith(searchQuery: event.query));
      unawaited(_applyWatchlistFilter(emit));
      return;
    }
    final snapshot = state.snapshot;
    if (snapshot == null) {
      emit(state.copyWith(searchQuery: event.query));
      return;
    }
    final visible = _applyFilters(
      coins: snapshot.coins,
      query: event.query,
      filter: state.filter,
      watchedIds: state.watchedIds,
    );
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleCoins: visible,
        status: MarketsStatus.loaded,
        clearFailure: true,
      ),
    );
    _syncLiveSubscriptions(visible);
  }

  void _onFilterChanged(
    MarketsFilterChanged event,
    Emitter<MarketsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
    if (event.filter == MarketFilter.watchlist) {
      unawaited(_applyWatchlistFilter(emit));
      return;
    }
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return;
    }
    final visible = _applyFilters(
      coins: snapshot.coins,
      query: state.searchQuery,
      filter: event.filter,
      watchedIds: state.watchedIds,
    );
    emit(
      state.copyWith(
        visibleCoins: visible,
        status: MarketsStatus.loaded,
        clearFailure: true,
      ),
    );
    _syncLiveSubscriptions(visible);
  }

  Future<void> _applyWatchlistFilter(Emitter<MarketsState> emit) async {
    final result = await _watchlistRepository.loadWatchlist();
    switch (result) {
      case Success(:final value, :final isStale):
        final visible = _applySearch(
          coins: value.coins,
          query: state.searchQuery,
        );
        emit(
          state.copyWith(
            visibleCoins: visible,
            isStale: isStale,
            status: MarketsStatus.loaded,
            clearFailure: true,
          ),
        );
        _rebuildCoinIndexForVisible(visible);
        _syncLiveSubscriptions(visible);
      case Failure(:final error):
        emit(
          state.copyWith(
            visibleCoins: const [],
            failure: error,
            status: MarketsStatus.failure,
          ),
        );
    }
  }

  void _onPriceTick(
    MarketsPriceTickReceived event,
    Emitter<MarketsState> emit,
  ) {
    final tick = event.tick;
    final pairKey = tick.symbol.toUpperCase();
    final displayPrice = _displayCurrency == DisplayCurrency.usd
        ? tick.lastPriceUsdt
        : tick.lastPriceEur;

    if (state.filter == MarketFilter.watchlist) {
      if (_coinIndexByBinancePair.isEmpty) {
        _rebuildCoinIndexForVisible(state.visibleCoins);
      }
      final coinIndex = _coinIndexByBinancePair[pairKey];
      if (coinIndex == null) {
        return;
      }
      final visible = List<MarketCoin>.from(state.visibleCoins);
      final coin = visible[coinIndex];
      visible[coinIndex] = coin.copyWith(
        currentPriceEur: displayPrice,
        priceChangePercent24h:
            tick.changePercent24h ?? coin.priceChangePercent24h,
        lastLiveTickAt: tick.eventTime,
      );
      emit(
        state.copyWith(
          visibleCoins: visible,
          liveFlashCoinId: coin.id,
          liveFlashGeneration: state.liveFlashGeneration + 1,
        ),
      );
      return;
    }

    final snapshot = state.snapshot;
    if (snapshot == null) {
      return;
    }
    if (_coinIndexByBinancePair.isEmpty) {
      _rebuildCoinIndex(snapshot.coins);
    }
    final coinIndex = _coinIndexByBinancePair[pairKey];
    if (coinIndex == null) {
      return;
    }
    final coins = List<MarketCoin>.from(snapshot.coins);
    final coin = coins[coinIndex];
    coins[coinIndex] = coin.copyWith(
      currentPriceEur: displayPrice,
      priceChangePercent24h:
          tick.changePercent24h ?? coin.priceChangePercent24h,
      lastLiveTickAt: tick.eventTime,
    );

    final visible = _applyFilters(
      coins: coins,
      query: state.searchQuery,
      filter: state.filter,
      watchedIds: state.watchedIds,
    );

    emit(
      state.copyWith(
        snapshot: snapshot.copyWith(coins: coins),
        visibleCoins: visible,
        liveFlashCoinId: coin.id,
        liveFlashGeneration: state.liveFlashGeneration + 1,
      ),
    );
  }

  void _onSymbolMappingUpdated(
    MarketsSymbolMappingUpdated event,
    Emitter<MarketsState> emit,
  ) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return;
    }
    final remapped = snapshot.coins
        .map((coin) => coin.withResolvedBinanceSymbol(_symbolMapper))
        .toList(growable: false);
    _rebuildCoinIndex(remapped);
    final visible = _applyFilters(
      coins: remapped,
      query: state.searchQuery,
      filter: state.filter,
      watchedIds: state.watchedIds,
    );
    emit(
      state.copyWith(
        snapshot: snapshot.copyWith(coins: remapped),
        visibleCoins: visible,
      ),
    );
    _syncLiveSubscriptions(visible);
  }

  void _onRealtimeStatus(
    MarketsRealtimeStatusChanged event,
    Emitter<MarketsState> emit,
  ) {
    emit(state.copyWith(realtimeStatus: event.status));
  }

  void _emitResult(
    Result<MarketsSnapshot> result,
    Emitter<MarketsState> emit, {
    required bool refreshAttempt,
  }) {
    switch (result) {
      case Success(:final value, :final isStale, :final refreshError):
        if (state.filter == MarketFilter.watchlist) {
          emit(
            MarketsState.loaded(
              snapshot: value,
              visibleCoins: state.visibleCoins,
              isStale: isStale,
              searchQuery: state.searchQuery,
              filter: state.filter,
              realtimeStatus: state.realtimeStatus,
            ).copyWith(
              watchedIds: state.watchedIds,
              refreshFailure: refreshAttempt ? refreshError : null,
            ),
          );
          unawaited(_applyWatchlistFilter(emit));
          return;
        }
        final visible = _applyFilters(
          coins: value.coins,
          query: state.searchQuery,
          filter: state.filter,
          watchedIds: state.watchedIds,
        );
        emit(
          MarketsState.loaded(
            snapshot: value,
            visibleCoins: visible,
            isStale: isStale,
            searchQuery: state.searchQuery,
            filter: state.filter,
            realtimeStatus: state.realtimeStatus,
          ).copyWith(
            watchedIds: state.watchedIds,
            refreshFailure: refreshAttempt ? refreshError : null,
          ),
        );
        _rebuildCoinIndex(value.coins);
        _syncLiveSubscriptions(visible);
      case Failure(:final error):
        if (state.snapshot != null) {
          emit(
            MarketsState.loaded(
              snapshot: state.snapshot!,
              visibleCoins: state.visibleCoins,
              isStale: state.isStale,
              searchQuery: state.searchQuery,
              filter: state.filter,
              realtimeStatus: state.realtimeStatus,
            ).copyWith(refreshFailure: refreshAttempt ? error : null),
          );
        } else {
          emit(MarketsState.failure(failure: error));
        }
    }
  }

  void _syncLiveSubscriptions(List<MarketCoin> visibleCoins) {
    final symbols = visibleCoins
        .where((coin) => coin.binanceSymbol != null)
        .take(maxLiveSubscriptions)
        .map((coin) => coin.binanceSymbol!.toLowerCase())
        .toSet();
    _subscriptionCoordinator.setSymbols(_marketsSubscriptionToken, symbols);
  }

  void _rebuildCoinIndex(List<MarketCoin> coins) {
    final index = <String, int>{};
    for (var i = 0; i < coins.length; i++) {
      final pair = coins[i].binanceSymbol?.toUpperCase();
      if (pair != null) {
        index[pair] = i;
      }
    }
    _coinIndexByBinancePair = index;
  }

  void _rebuildCoinIndexForVisible(List<MarketCoin> coins) {
    _rebuildCoinIndex(coins);
  }

  static List<MarketCoin> _applySearch({
    required List<MarketCoin> coins,
    required String query,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return coins;
    }
    return coins
        .where((coin) {
          return coin.name.toLowerCase().contains(normalized) ||
              coin.symbol.toLowerCase().contains(normalized) ||
              coin.id.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  /// Exposed for tests.
  static List<MarketCoin> applyFilters({
    required List<MarketCoin> coins,
    required String query,
    required MarketFilter filter,
    Set<String> watchedIds = const {},
  }) {
    return _applyFilters(
      coins: coins,
      query: query,
      filter: filter,
      watchedIds: watchedIds,
    );
  }

  static List<MarketCoin> _applyFilters({
    required List<MarketCoin> coins,
    required String query,
    required MarketFilter filter,
    Set<String> watchedIds = const {},
  }) {
    final normalized = query.trim().toLowerCase();
    Iterable<MarketCoin> filtered = coins;
    if (normalized.isNotEmpty) {
      filtered = filtered.where((coin) {
        return coin.name.toLowerCase().contains(normalized) ||
            coin.symbol.toLowerCase().contains(normalized) ||
            coin.id.toLowerCase().contains(normalized);
      });
    }
    filtered = switch (filter) {
      MarketFilter.all => filtered,
      MarketFilter.gainers => filtered.where(
        (c) => c.priceChangePercent24h > 0,
      ),
      MarketFilter.losers => filtered.where((c) => c.priceChangePercent24h < 0),
      MarketFilter.watchlist => filtered.where(
        (c) => watchedIds.contains(c.id),
      ),
    };
    return filtered.toList(growable: false);
  }

  @override
  Future<void> close() {
    _tickSubscription?.cancel();
    _statusSubscription?.cancel();
    _mapperSubscription?.cancel();
    _settingsSubscription?.cancel();
    _watchlistMembershipSubscription?.cancel();
    _subscriptionCoordinator.removeToken(_marketsSubscriptionToken);
    return super.close();
  }
}
