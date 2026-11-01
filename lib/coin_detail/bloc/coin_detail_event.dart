part of 'coin_detail_bloc.dart';

sealed class CoinDetailEvent extends Equatable {
  const CoinDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Loads detail and initial chart for [coinId].
final class CoinDetailStarted extends CoinDetailEvent {
  const CoinDetailStarted(this.coinId);

  final String coinId;

  @override
  List<Object?> get props => [coinId];
}

/// User selected a new chart period.
final class CoinDetailChartRangeChanged extends CoinDetailEvent {
  const CoinDetailChartRangeChanged(this.range);

  final ChartPeriod range;

  @override
  List<Object?> get props => [range];
}

/// Retry after error (metadata + chart).
final class CoinDetailRetryRequested extends CoinDetailEvent {
  const CoinDetailRetryRequested();
}

/// Live tick from [PriceStreamService].
final class CoinDetailPriceTickReceived extends CoinDetailEvent {
  const CoinDetailPriceTickReceived(this.tick);

  final PriceTick tick;

  @override
  List<Object?> get props => [tick];
}

/// Connection status update.
final class CoinDetailRealtimeStatusChanged extends CoinDetailEvent {
  const CoinDetailRealtimeStatusChanged(this.status);

  final RealtimeStatus status;

  @override
  List<Object?> get props => [status];
}

/// Watchlist star tapped.
final class CoinDetailWatchlistToggled extends CoinDetailEvent {
  const CoinDetailWatchlistToggled();
}

/// Display currency changed in settings.
final class CoinDetailPreferencesChanged extends CoinDetailEvent {
  const CoinDetailPreferencesChanged();
}
