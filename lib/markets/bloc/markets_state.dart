part of 'markets_bloc.dart';

/// Lifecycle status for the markets screen.
enum MarketsStatus { initial, loading, loaded, failure }

/// Immutable markets UI state.
final class MarketsState extends Equatable {
  /// Creates state.
  const MarketsState({
    this.status = MarketsStatus.initial,
    this.snapshot,
    this.isStale = false,
    this.searchQuery = '',
    this.filter = MarketFilter.all,
    this.visibleCoins = const [],
    this.failure,
    this.refreshFailure,
  });

  /// Initial state before first load.
  const MarketsState.initial() : this();

  /// Loading with optional previous data for pull-to-refresh.
  const MarketsState.loading({
    MarketsSnapshot? snapshot,
    bool isStale = false,
    String searchQuery = '',
    MarketFilter filter = MarketFilter.all,
    List<MarketCoin> visibleCoins = const [],
  }) : this(
         status: MarketsStatus.loading,
         snapshot: snapshot,
         isStale: isStale,
         searchQuery: searchQuery,
         filter: filter,
         visibleCoins: visibleCoins,
       );

  /// Loaded or stale-loaded state.
  const MarketsState.loaded({
    required MarketsSnapshot snapshot,
    required List<MarketCoin> visibleCoins,
    bool isStale = false,
    String searchQuery = '',
    MarketFilter filter = MarketFilter.all,
  }) : this(
         status: MarketsStatus.loaded,
         snapshot: snapshot,
         isStale: isStale,
         searchQuery: searchQuery,
         filter: filter,
         visibleCoins: visibleCoins,
       );

  /// Full-screen failure when no data to show.
  const MarketsState.failure({
    required AppFailure failure,
    MarketsSnapshot? snapshot,
  }) : this(
         status: MarketsStatus.failure,
         failure: failure,
         snapshot: snapshot,
       );

  /// Current status.
  final MarketsStatus status;

  /// Last successful snapshot (may back stale UI).
  final MarketsSnapshot? snapshot;

  /// True when data is from expired cache.
  final bool isStale;

  /// Client search string.
  final String searchQuery;

  /// Active list filter chip.
  final MarketFilter filter;

  /// Coins after search + filter.
  final List<MarketCoin> visibleCoins;

  /// Error when [status] is [MarketsStatus.failure].
  final AppFailure? failure;

  /// One-shot error from pull-to-refresh (snackbar).
  final AppFailure? refreshFailure;

  /// Cache timestamp for stale banner.
  DateTime? get fetchedAt => snapshot?.fetchedAt;

  MarketsState copyWith({
    MarketsStatus? status,
    MarketsSnapshot? snapshot,
    bool? isStale,
    String? searchQuery,
    MarketFilter? filter,
    List<MarketCoin>? visibleCoins,
    AppFailure? failure,
    AppFailure? refreshFailure,
    bool clearFailure = false,
    bool clearRefreshFailure = false,
  }) {
    return MarketsState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      isStale: isStale ?? this.isStale,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      visibleCoins: visibleCoins ?? this.visibleCoins,
      failure: clearFailure ? null : failure ?? this.failure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    snapshot,
    isStale,
    searchQuery,
    filter,
    visibleCoins,
    failure,
    refreshFailure,
  ];
}
