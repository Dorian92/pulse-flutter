part of 'watchlist_bloc.dart';

/// Watchlist screen status.
enum WatchlistStatus { initial, loading, loaded, failure }

/// Immutable watchlist UI state.
class WatchlistState extends Equatable {
  const WatchlistState({
    required this.status,
    required this.coins,
    required this.isStale,
    required this.isEditing,
    required this.realtimeStatus,
    this.fetchedAt,
    this.failure,
    this.pendingUndo,
    this.liveFlashCoinId,
    this.liveFlashGeneration = 0,
    this.refreshFailure,
  });

  const WatchlistState.initial()
    : status = WatchlistStatus.initial,
      coins = const [],
      isStale = false,
      isEditing = false,
      realtimeStatus = const RealtimeStatus.offline(),
      fetchedAt = null,
      failure = null,
      pendingUndo = null,
      liveFlashCoinId = null,
      liveFlashGeneration = 0,
      refreshFailure = null;

  final WatchlistStatus status;
  final List<MarketCoin> coins;
  final bool isStale;
  final bool isEditing;
  final RealtimeStatus realtimeStatus;
  final DateTime? fetchedAt;
  final AppFailure? failure;
  final WatchlistUndoPayload? pendingUndo;
  final String? liveFlashCoinId;
  final int liveFlashGeneration;
  final AppFailure? refreshFailure;

  WatchlistState copyWith({
    WatchlistStatus? status,
    List<MarketCoin>? coins,
    bool? isStale,
    bool? isEditing,
    RealtimeStatus? realtimeStatus,
    DateTime? fetchedAt,
    AppFailure? failure,
    WatchlistUndoPayload? pendingUndo,
    String? liveFlashCoinId,
    int? liveFlashGeneration,
    AppFailure? refreshFailure,
    bool clearFailure = false,
    bool clearPendingUndo = false,
    bool clearRefreshFailure = false,
  }) {
    return WatchlistState(
      status: status ?? this.status,
      coins: coins ?? this.coins,
      isStale: isStale ?? this.isStale,
      isEditing: isEditing ?? this.isEditing,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      failure: clearFailure ? null : (failure ?? this.failure),
      pendingUndo: clearPendingUndo ? null : (pendingUndo ?? this.pendingUndo),
      liveFlashCoinId: liveFlashCoinId ?? this.liveFlashCoinId,
      liveFlashGeneration: liveFlashGeneration ?? this.liveFlashGeneration,
      refreshFailure: clearRefreshFailure
          ? null
          : (refreshFailure ?? this.refreshFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    coins,
    isStale,
    isEditing,
    realtimeStatus,
    fetchedAt,
    failure,
    pendingUndo,
    liveFlashCoinId,
    liveFlashGeneration,
    refreshFailure,
  ];
}
