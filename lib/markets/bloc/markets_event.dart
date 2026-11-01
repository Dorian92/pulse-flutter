part of 'markets_bloc.dart';

sealed class MarketsEvent extends Equatable {
  const MarketsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load when the page opens.
final class MarketsRequested extends MarketsEvent {
  const MarketsRequested();
}

/// Pull-to-refresh (bypasses cache TTL).
final class MarketsRefreshRequested extends MarketsEvent {
  const MarketsRefreshRequested();
}

/// Client search query changed.
final class MarketsSearchQueryChanged extends MarketsEvent {
  const MarketsSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Filter chip selection changed.
final class MarketsFilterChanged extends MarketsEvent {
  const MarketsFilterChanged(this.filter);

  final MarketFilter filter;

  @override
  List<Object?> get props => [filter];
}
