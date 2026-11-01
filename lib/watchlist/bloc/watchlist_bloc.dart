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
    on<WatchlistMembershipChanged>(_onMembershipChanged);

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
    _membershipSubscription = _repository.membershipChanges.listen((_) {
      add(const WatchlistMembershipChanged());
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
  StreamSubscription<void>? _membershipSubscription;

  /// Maps Binance pair → index in [WatchlistState.entries] (coin rows only).
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

  Future<void> _onMembershipChanged(
    WatchlistMembershipChanged event,
    Emitter<WatchlistState> emit,
  ) async {
    if (state.status == WatchlistStatus.initial) {
      return;
    }
    final result = await _repository.loadWatchlist();
    _emitLoadResult(result, emit, refreshAttempt: false);
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
    final index = state.entries.indexWhere((e) => e.coinId == event.coinId);
    if (index < 0) {
      return;
    }
    final entry = state.entries[index];
    await _repository.setWatched(event.coinId, watched: false);
    final nextEntries = List<WatchlistEntry>.from(state.entries)
      ..removeAt(index);
    emit(
      state.copyWith(
        entries: nextEntries,
        pendingUndo: WatchlistUndoPayload(
          coinId: event.coinId,
          index: index,
          entry: entry,
        ),
      ),
    );
    _syncLiveSubscriptions(_coinsFromEntries(nextEntries));
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
    final nextEntries = List<WatchlistEntry>.from(state.entries);
    final clamped = undo.index.clamp(0, nextEntries.length);
    nextEntries.insert(clamped, undo.entry);
    emit(state.copyWith(entries: nextEntries, clearPendingUndo: true));
    _syncLiveSubscriptions(_coinsFromEntries(nextEntries));
  }

  Future<void> _onReorder(
    WatchlistReorderRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    await _repository.reorder(
      oldIndex: event.oldIndex,
      newIndex: event.newIndex,
    );
    final entries = List<WatchlistEntry>.from(state.entries);
    final item = entries.removeAt(event.oldIndex);
    entries.insert(event.newIndex, item);
    emit(state.copyWith(entries: entries));
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
    if (state.entries.isEmpty) {
      return;
    }
    if (_coinIndexByBinancePair.isEmpty) {
      _rebuildCoinIndex(state.entries);
    }
    final tick = event.tick;
    final entryIndex = _coinIndexByBinancePair[tick.symbol.toUpperCase()];
    if (entryIndex == null) {
      return;
    }
    final entry = state.entries[entryIndex];
    final coin = entry.coin;
    if (coin == null) {
      return;
    }
    final displayPrice = _displayCurrency == DisplayCurrency.usd
        ? tick.lastPriceUsdt
        : tick.lastPriceEur;
    final updatedCoin = coin.copyWith(
      currentPriceEur: displayPrice,
      priceChangePercent24h:
          tick.changePercent24h ?? coin.priceChangePercent24h,
      lastLiveTickAt: tick.eventTime,
    );
    final entries = List<WatchlistEntry>.from(state.entries);
    entries[entryIndex] = WatchlistEntry(
      coinId: entry.coinId,
      coin: updatedCoin,
    );
    emit(
      state.copyWith(
        entries: entries,
        liveFlashCoinId: coin.id,
        liveFlashGeneration: state.liveFlashGeneration + 1,
      ),
    );
  }

  void _onSymbolMappingUpdated(
    WatchlistSymbolMappingUpdated event,
    Emitter<WatchlistState> emit,
  ) {
    if (state.entries.isEmpty) {
      return;
    }
    final remapped = state.entries
        .map((entry) {
          final coin = entry.coin;
          if (coin == null) {
            return entry;
          }
          return WatchlistEntry(
            coinId: entry.coinId,
            coin: coin.withResolvedBinanceSymbol(_symbolMapper),
          );
        })
        .toList(growable: false);
    _rebuildCoinIndex(remapped);
    emit(state.copyWith(entries: remapped));
    _syncLiveSubscriptions(_coinsFromEntries(remapped));
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
        _rebuildCoinIndex(value.entries);
        emit(
          state.copyWith(
            status: WatchlistStatus.loaded,
            entries: value.entries,
            isStale: isStale,
            fetchedAt: value.fetchedAt,
            clearFailure: true,
            refreshFailure: refreshAttempt ? refreshError : null,
          ),
        );
        _syncLiveSubscriptions(value.coins);
      case Failure(:final error):
        if (state.entries.isNotEmpty) {
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

  List<MarketCoin> _coinsFromEntries(List<WatchlistEntry> entries) {
    return entries
        .where((entry) => entry.coin != null)
        .map((entry) => entry.coin!)
        .toList(growable: false);
  }

  void _syncLiveSubscriptions(List<MarketCoin> coins) {
    final symbols = coins
        .where((coin) => coin.binanceSymbol != null)
        .map((coin) => coin.binanceSymbol!.toLowerCase())
        .toSet();
    _subscriptionCoordinator.setSymbols(_watchlistSubscriptionToken, symbols);
  }

  void _rebuildCoinIndex(List<WatchlistEntry> entries) {
    final index = <String, int>{};
    for (var i = 0; i < entries.length; i++) {
      final pair = entries[i].coin?.binanceSymbol?.toUpperCase();
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
    _membershipSubscription?.cancel();
    _subscriptionCoordinator.removeToken(_watchlistSubscriptionToken);
    return super.close();
  }
}
