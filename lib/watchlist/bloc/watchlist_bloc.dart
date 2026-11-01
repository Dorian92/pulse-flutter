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
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

/// Loads watchlist rows, live ticks, reorder, and undo remove.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  /// Creates a watchlist bloc.
  WatchlistBloc({
    required WatchlistRepository repository,
    required RealtimeSubscriptionCoordinator subscriptionCoordinator,
    required PriceStreamService priceStreamService,
    required SymbolMapper symbolMapper,
    required SettingsRepository settingsRepository,
  }) : _repository = repository,
       _subscriptionCoordinator = subscriptionCoordinator,
       _priceStreamService = priceStreamService,
       _symbolMapper = symbolMapper,
       _settingsRepository = settingsRepository,
       super(const WatchlistState.initial()) {
    on<WatchlistRequested>(_onRequested);
    on<WatchlistRefreshRequested>(_onRefresh, transformer: droppable());
    on<WatchlistEditingToggled>(_onEditingToggled);
    on<WatchlistRemoveRequested>(_onRemove);
    on<WatchlistUndoRemoveRequested>(_onUndoRemove);
    on<WatchlistReorderRequested>(_onReorder);
    on<WatchlistPriceTickReceived>(_onPriceTick, transformer: sequential());
    on<WatchlistRealtimeStatusChanged>(_onRealtimeStatus);
    on<WatchlistSymbolMappingUpdated>(_onSymbolMappingUpdated);
    on<WatchlistPreferencesChanged>(_onPreferencesChanged);

    _tickSubscription = _priceStreamService.ticks.listen(
      (tick) => add(WatchlistPriceTickReceived(tick)),
    );
    _statusSubscription = _priceStreamService.status.listen(
      (status) => add(WatchlistRealtimeStatusChanged(status)),
    );
    _mapperSubscription = _symbolMapper.updates.listen((_) {
      add(const WatchlistSymbolMappingUpdated());
    });
    _settingsSubscription = _settingsRepository.changes.listen((_) {
      add(const WatchlistPreferencesChanged());
    });
  }

  static const String _watchlistSubscriptionToken = 'watchlist';

  final WatchlistRepository _repository;
  final RealtimeSubscriptionCoordinator _subscriptionCoordinator;
  final PriceStreamService _priceStreamService;
  final SymbolMapper _symbolMapper;
  final SettingsRepository _settingsRepository;

  StreamSubscription<PriceTick>? _tickSubscription;
  StreamSubscription<RealtimeStatus>? _statusSubscription;
  StreamSubscription<int>? _mapperSubscription;
  StreamSubscription<UserPreferences>? _settingsSubscription;

  Map<String, int> _coinIndexByBinancePair = {};

  DisplayCurrency get _displayCurrency =>
      _settingsRepository.current.displayCurrency;

  Future<void> _onRequested(
    WatchlistRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WatchlistStatus.loading,
        clearFailure: true,
        clearRefreshFailure: true,
      ),
    );
    final result = await _repository.loadWatchlist();
    _emitLoadResult(result, emit, refreshAttempt: false);
  }

  Future<void> _onRefresh(
    WatchlistRefreshRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(state.copyWith(status: WatchlistStatus.loading));
    final result = await _repository.refreshWatchlist();
    _emitLoadResult(result, emit, refreshAttempt: true);
  }

  void _onEditingToggled(
    WatchlistEditingToggled event,
    Emitter<WatchlistState> emit,
  ) {
    emit(state.copyWith(isEditing: !state.isEditing));
  }

  Future<void> _onRemove(
    WatchlistRemoveRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    final index = state.coins.indexWhere((c) => c.id == event.coinId);
    if (index < 0) {
      return;
    }
    final coin = state.coins[index];
    await _repository.setWatched(event.coinId, watched: false);
    final nextCoins = List<MarketCoin>.from(state.coins)..removeAt(index);
    emit(
      state.copyWith(
        coins: nextCoins,
        pendingUndo: WatchlistUndoPayload(
          coinId: event.coinId,
          index: index,
          coin: coin,
        ),
      ),
    );
    _syncLiveSubscriptions(nextCoins);
  }

  Future<void> _onUndoRemove(
    WatchlistUndoRemoveRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    final undo = state.pendingUndo;
    if (undo == null) {
      return;
    }
    await _repository.insertAt(coinId: undo.coinId, index: undo.index);
    final nextCoins = List<MarketCoin>.from(state.coins);
    final clamped = undo.index.clamp(0, nextCoins.length);
    nextCoins.insert(clamped, undo.coin);
    emit(state.copyWith(coins: nextCoins, clearPendingUndo: true));
    _syncLiveSubscriptions(nextCoins);
  }

  Future<void> _onReorder(
    WatchlistReorderRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    await _repository.reorder(
      oldIndex: event.oldIndex,
      newIndex: event.newIndex,
    );
    final coins = List<MarketCoin>.from(state.coins);
    final item = coins.removeAt(event.oldIndex);
    coins.insert(event.newIndex, item);
    emit(state.copyWith(coins: coins));
  }

  Future<void> _onPreferencesChanged(
    WatchlistPreferencesChanged event,
    Emitter<WatchlistState> emit,
  ) async {
    add(const WatchlistRequested());
  }

  void _onPriceTick(
    WatchlistPriceTickReceived event,
    Emitter<WatchlistState> emit,
  ) {
    if (state.coins.isEmpty) {
      return;
    }
    if (_coinIndexByBinancePair.isEmpty) {
      _rebuildCoinIndex(state.coins);
    }
    final tick = event.tick;
    final coinIndex = _coinIndexByBinancePair[tick.symbol.toUpperCase()];
    if (coinIndex == null) {
      return;
    }
    final coins = List<MarketCoin>.from(state.coins);
    final coin = coins[coinIndex];
    final displayPrice = _displayCurrency == DisplayCurrency.usd
        ? tick.lastPriceUsdt
        : tick.lastPriceEur;
    coins[coinIndex] = coin.copyWith(
      currentPriceEur: displayPrice,
      priceChangePercent24h:
          tick.changePercent24h ?? coin.priceChangePercent24h,
      lastLiveTickAt: tick.eventTime,
    );
    emit(
      state.copyWith(
        coins: coins,
        liveFlashCoinId: coin.id,
        liveFlashGeneration: state.liveFlashGeneration + 1,
      ),
    );
  }

  void _onSymbolMappingUpdated(
    WatchlistSymbolMappingUpdated event,
    Emitter<WatchlistState> emit,
  ) {
    if (state.coins.isEmpty) {
      return;
    }
    final remapped = state.coins
        .map((coin) => coin.withResolvedBinanceSymbol(_symbolMapper))
        .toList(growable: false);
    _rebuildCoinIndex(remapped);
    emit(state.copyWith(coins: remapped));
    _syncLiveSubscriptions(remapped);
  }

  void _onRealtimeStatus(
    WatchlistRealtimeStatusChanged event,
    Emitter<WatchlistState> emit,
  ) {
    emit(state.copyWith(realtimeStatus: event.status));
  }

  void _emitLoadResult(
    Result<WatchlistSnapshot> result,
    Emitter<WatchlistState> emit, {
    required bool refreshAttempt,
  }) {
    switch (result) {
      case Success(:final value, :final isStale, :final refreshError):
        _rebuildCoinIndex(value.coins);
        emit(
          state.copyWith(
            status: WatchlistStatus.loaded,
            coins: value.coins,
            isStale: isStale,
            fetchedAt: value.fetchedAt,
            clearFailure: true,
            refreshFailure: refreshAttempt ? refreshError : null,
          ),
        );
        _syncLiveSubscriptions(value.coins);
      case Failure(:final error):
        if (state.coins.isNotEmpty) {
          emit(
            state.copyWith(
              status: WatchlistStatus.loaded,
              refreshFailure: refreshAttempt ? error : null,
            ),
          );
        } else {
          emit(state.copyWith(status: WatchlistStatus.failure, failure: error));
        }
    }
  }

  void _syncLiveSubscriptions(List<MarketCoin> coins) {
    final symbols = coins
        .where((coin) => coin.binanceSymbol != null)
        .map((coin) => coin.binanceSymbol!.toLowerCase())
        .toSet();
    _subscriptionCoordinator.setSymbols(_watchlistSubscriptionToken, symbols);
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

  @override
  Future<void> close() {
    _tickSubscription?.cancel();
    _statusSubscription?.cancel();
    _mapperSubscription?.cancel();
    _settingsSubscription?.cancel();
    _subscriptionCoordinator.removeToken(_watchlistSubscriptionToken);
    return super.close();
  }
}
