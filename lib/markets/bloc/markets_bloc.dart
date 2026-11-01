import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';

part 'markets_event.dart';
part 'markets_state.dart';

/// Manages markets list loading, refresh, search, and filters.
class MarketsBloc extends Bloc<MarketsEvent, MarketsState> {
  /// Creates a bloc with [repository].
  MarketsBloc({required MarketsRepository repository})
    : _repository = repository,
      super(const MarketsState.initial()) {
    on<MarketsRequested>(_onRequested);
    on<MarketsRefreshRequested>(_onRefresh, transformer: droppable());
    on<MarketsSearchQueryChanged>(_onSearchChanged, transformer: restartable());
    on<MarketsFilterChanged>(_onFilterChanged);
  }

  final MarketsRepository _repository;

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
      ).copyWith(clearRefreshFailure: true),
    );

    final result = await _repository.loadMarkets();
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
      ),
    );

    final result = await _repository.refreshMarkets();
    _emitResult(result, emit, refreshAttempt: true);
  }

  void _onSearchChanged(
    MarketsSearchQueryChanged event,
    Emitter<MarketsState> emit,
  ) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      emit(state.copyWith(searchQuery: event.query));
      return;
    }
    final visible = _applyFilters(
      coins: snapshot.coins,
      query: event.query,
      filter: state.filter,
    );
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleCoins: visible,
        status: MarketsStatus.loaded,
        clearFailure: true,
      ),
    );
  }

  void _onFilterChanged(
    MarketsFilterChanged event,
    Emitter<MarketsState> emit,
  ) {
    if (event.filter == MarketFilter.watchlist) {
      return;
    }
    final snapshot = state.snapshot;
    if (snapshot == null) {
      emit(state.copyWith(filter: event.filter));
      return;
    }
    final visible = _applyFilters(
      coins: snapshot.coins,
      query: state.searchQuery,
      filter: event.filter,
    );
    emit(
      state.copyWith(
        filter: event.filter,
        visibleCoins: visible,
        status: MarketsStatus.loaded,
        clearFailure: true,
      ),
    );
  }

  void _emitResult(
    Result<MarketsSnapshot> result,
    Emitter<MarketsState> emit, {
    required bool refreshAttempt,
  }) {
    switch (result) {
      case Success(:final value, :final isStale):
        final visible = _applyFilters(
          coins: value.coins,
          query: state.searchQuery,
          filter: state.filter,
        );
        emit(
          MarketsState.loaded(
            snapshot: value,
            visibleCoins: visible,
            isStale: isStale,
            searchQuery: state.searchQuery,
            filter: state.filter,
          ).copyWith(
            refreshFailure: refreshAttempt && isStale
                ? const NetworkFailure(offline: true)
                : null,
          ),
        );
      case Failure(:final error):
        if (state.snapshot != null) {
          emit(
            MarketsState.loaded(
              snapshot: state.snapshot!,
              visibleCoins: state.visibleCoins,
              isStale: state.isStale,
              searchQuery: state.searchQuery,
              filter: state.filter,
            ).copyWith(refreshFailure: refreshAttempt ? error : null),
          );
        } else {
          emit(MarketsState.failure(failure: error));
        }
    }
  }

  /// Exposed for tests.
  static List<MarketCoin> applyFilters({
    required List<MarketCoin> coins,
    required String query,
    required MarketFilter filter,
  }) {
    return _applyFilters(coins: coins, query: query, filter: filter);
  }

  static List<MarketCoin> _applyFilters({
    required List<MarketCoin> coins,
    required String query,
    required MarketFilter filter,
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
      MarketFilter.watchlist => filtered,
    };
    return filtered.toList(growable: false);
  }
}
