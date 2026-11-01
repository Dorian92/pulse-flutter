part of 'watchlist_bloc.dart';

sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

final class WatchlistRequested extends WatchlistEvent {
  const WatchlistRequested();
}

final class WatchlistRefreshRequested extends WatchlistEvent {
  const WatchlistRefreshRequested();
}

final class WatchlistEditingToggled extends WatchlistEvent {
  const WatchlistEditingToggled();
}

final class WatchlistRemoveRequested extends WatchlistEvent {
  const WatchlistRemoveRequested(this.coinId);

  final String coinId;

  @override
  List<Object?> get props => [coinId];
}

final class WatchlistUndoRemoveRequested extends WatchlistEvent {
  const WatchlistUndoRemoveRequested();
}

final class WatchlistReorderRequested extends WatchlistEvent {
  const WatchlistReorderRequested({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

final class WatchlistPriceTickReceived extends WatchlistEvent {
  const WatchlistPriceTickReceived(this.tick);

  final PriceTick tick;

  @override
  List<Object?> get props => [tick];
}

final class WatchlistRealtimeStatusChanged extends WatchlistEvent {
  const WatchlistRealtimeStatusChanged(this.status);

  final RealtimeStatus status;

  @override
  List<Object?> get props => [status];
}

final class WatchlistSymbolMappingUpdated extends WatchlistEvent {
  const WatchlistSymbolMappingUpdated();
}

final class WatchlistPreferencesChanged extends WatchlistEvent {
  const WatchlistPreferencesChanged();
}

final class WatchlistMembershipChanged extends WatchlistEvent {
  const WatchlistMembershipChanged();
}
