import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/coin_detail/watchlist/watchlist_toggle.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/widgets/period_selector.dart';

part 'coin_detail_event.dart';
part 'coin_detail_state.dart';

/// Loads coin detail, chart ranges, and live price for one coin.
class CoinDetailBloc extends Bloc<CoinDetailEvent, CoinDetailState> {
  /// Creates a bloc with injected dependencies.
  CoinDetailBloc({
    required CoinDetailRepository repository,
    required RealtimeSubscriptionCoordinator subscriptionCoordinator,
    required PriceStreamService priceStreamService,
    required WatchlistToggle watchlistToggle,
  }) : _repository = repository,
       _subscriptionCoordinator = subscriptionCoordinator,
       _priceStreamService = priceStreamService,
       _watchlistToggle = watchlistToggle,
       super(const CoinDetailState.initial()) {
    on<CoinDetailStarted>(_onStarted);
    on<CoinDetailChartRangeChanged>(
      _onRangeChanged,
      transformer: restartable(),
    );
    on<CoinDetailRetryRequested>(_onRetry);
    on<CoinDetailPriceTickReceived>(_onPriceTick);
    on<CoinDetailRealtimeStatusChanged>(_onRealtimeStatus);
    on<CoinDetailWatchlistToggled>(_onWatchlistToggled);

    _tickSubscription = _priceStreamService.ticks.listen(
      (tick) => add(CoinDetailPriceTickReceived(tick)),
    );
    _statusSubscription = _priceStreamService.status.listen(
      (status) => add(CoinDetailRealtimeStatusChanged(status)),
    );
  }

  final CoinDetailRepository _repository;
  final RealtimeSubscriptionCoordinator _subscriptionCoordinator;
  final PriceStreamService _priceStreamService;
  final WatchlistToggle _watchlistToggle;

  StreamSubscription<PriceTick>? _tickSubscription;
  StreamSubscription<RealtimeStatus>? _statusSubscription;

  String? _subscriptionToken;

  Future<void> _onStarted(
    CoinDetailStarted event,
    Emitter<CoinDetailState> emit,
  ) async {
    emit(CoinDetailState.loading(coinId: event.coinId));

    final watched = await _watchlistToggle.isWatched(event.coinId);
    final detailResult = await _repository.loadDetail(event.coinId);

    switch (detailResult) {
      case Failure(:final error):
        emit(CoinDetailState.failure(coinId: event.coinId, failure: error));
        return;
      case Success(:final value, :final isStale):
        _registerLiveSubscription(value);
        final chartResult = await _repository.loadChart(
          coinId: event.coinId,
          range: ChartPeriod.oneDay,
          binanceSymbol: value.binanceSymbol,
        );
        emit(
          _loadedFromResults(
            coinId: event.coinId,
            detail: value,
            chartResult: chartResult,
            selectedRange: ChartPeriod.oneDay,
            isWatchlisted: watched,
            detailStale: isStale,
          ),
        );
    }
  }

  Future<void> _onRangeChanged(
    CoinDetailChartRangeChanged event,
    Emitter<CoinDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null) {
      return;
    }
    emit(
      state.copyWith(
        selectedRange: event.range,
        chartLoading: true,
        clearChartFailure: true,
      ),
    );

    final chartResult = await _repository.loadChart(
      coinId: state.coinId,
      range: event.range,
      binanceSymbol: detail.binanceSymbol,
    );

    switch (chartResult) {
      case Success(:final value, :final isStale):
        emit(
          state.copyWith(
            chart: value,
            chartLoading: false,
            isStale: state.isStale || isStale,
            clearChartFailure: true,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(chartLoading: false, chartFailure: error));
    }
  }

  Future<void> _onRetry(
    CoinDetailRetryRequested event,
    Emitter<CoinDetailState> emit,
  ) async {
    final coinId = state.coinId;
    if (coinId.isEmpty) {
      return;
    }
    final range = state.selectedRange;
    emit(CoinDetailState.loading(coinId: coinId, selectedRange: range));

    final watched = await _watchlistToggle.isWatched(coinId);
    final detailResult = await _repository.refreshDetail(coinId);
    switch (detailResult) {
      case Failure(:final error):
        emit(CoinDetailState.failure(coinId: coinId, failure: error));
        return;
      case Success(:final value, :final isStale):
        _registerLiveSubscription(value);
        final chartResult = await _repository.refreshChart(
          coinId: coinId,
          range: range,
          binanceSymbol: value.binanceSymbol,
        );
        emit(
          _loadedFromResults(
            coinId: coinId,
            detail: value,
            chartResult: chartResult,
            selectedRange: range,
            isWatchlisted: watched,
            detailStale: isStale,
          ),
        );
    }
  }

  CoinDetailState _loadedFromResults({
    required String coinId,
    required CoinDetail detail,
    required Result<PriceChartSeries> chartResult,
    required ChartPeriod selectedRange,
    required bool isWatchlisted,
    required bool detailStale,
  }) {
    final chart = switch (chartResult) {
      Success(:final value) => value,
      Failure() => null,
    };
    final chartFailure = switch (chartResult) {
      Failure(:final error) => error,
      Success() => null,
    };
    final chartStale = switch (chartResult) {
      Success(isStale: true) => true,
      _ => false,
    };
    return CoinDetailState.loaded(
      coinId: coinId,
      detail: detail,
      chart: chart,
      selectedRange: selectedRange,
      livePriceEur: detail.currentPriceEur,
      changePercent24h: detail.priceChangePercent24h,
      realtimeStatus: _initialRealtimeStatus(detail),
      isStale: detailStale || chartStale,
      chartLoading: false,
      chartFailure: chartFailure,
      isWatchlisted: isWatchlisted,
      fetchedAt: detail.fetchedAt,
    );
  }

  RealtimeStatus _initialRealtimeStatus(CoinDetail detail) {
    if (!detail.hasLiveFeed) {
      return const RealtimeStatus.offline();
    }
    final current = _priceStreamService.currentStatus;
    if (current is RealtimeOffline) {
      return const RealtimeStatus.connecting();
    }
    return current;
  }

  void _onPriceTick(
    CoinDetailPriceTickReceived event,
    Emitter<CoinDetailState> emit,
  ) {
    final detail = state.detail;
    if (detail == null || detail.binanceSymbol == null) {
      return;
    }
    if (event.tick.symbol.toUpperCase() !=
        detail.binanceSymbol!.toUpperCase()) {
      return;
    }
    emit(
      state.copyWith(
        livePriceEur: event.tick.lastPriceEur,
        changePercent24h: event.tick.changePercent24h ?? state.changePercent24h,
        detail: detail.copyWith(
          currentPriceEur: event.tick.lastPriceEur,
          priceChangePercent24h:
              event.tick.changePercent24h ?? detail.priceChangePercent24h,
        ),
      ),
    );
  }

  void _onRealtimeStatus(
    CoinDetailRealtimeStatusChanged event,
    Emitter<CoinDetailState> emit,
  ) {
    emit(state.copyWith(realtimeStatus: event.status));
  }

  Future<void> _onWatchlistToggled(
    CoinDetailWatchlistToggled event,
    Emitter<CoinDetailState> emit,
  ) async {
    final coinId = state.coinId;
    if (coinId.isEmpty) {
      return;
    }
    final next = !state.isWatchlisted;
    await _watchlistToggle.setWatched(coinId, watched: next);
    emit(state.copyWith(isWatchlisted: next));
  }

  void _registerLiveSubscription(CoinDetail detail) {
    final token = 'coin_detail:${detail.id}';
    _subscriptionToken = token;
    final symbol = detail.binanceSymbol?.toLowerCase();
    if (symbol == null) {
      _subscriptionCoordinator.setSymbols(token, {});
      return;
    }
    _subscriptionCoordinator.setSymbols(token, {symbol});
  }

  @override
  Future<void> close() {
    _tickSubscription?.cancel();
    _statusSubscription?.cancel();
    if (_subscriptionToken != null) {
      _subscriptionCoordinator.removeToken(_subscriptionToken!);
    }
    return super.close();
  }
}
