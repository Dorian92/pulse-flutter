import 'dart:async';

import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_local_data_source.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_markets_data_source.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';

/// Merges persisted ids with markets cache and supplemental CoinGecko fetch.
class WatchlistRepositoryImpl implements WatchlistRepository {
  /// Creates the repository.
  WatchlistRepositoryImpl({
    required WatchlistLocalDataSource local,
    required MarketsRepository marketsRepository,
    required WatchlistMarketsDataSource supplementalMarkets,
    required ConnectivityService connectivity,
  }) : _local = local,
       _marketsRepository = marketsRepository,
       _supplementalMarkets = supplementalMarkets,
       _connectivity = connectivity;

  final WatchlistLocalDataSource _local;
  final MarketsRepository _marketsRepository;
  final WatchlistMarketsDataSource _supplementalMarkets;
  final ConnectivityService _connectivity;

  final StreamController<void> _membershipController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get membershipChanges => _membershipController.stream;

  void _notifyMembershipChanged() {
    if (!_membershipController.isClosed) {
      _membershipController.add(null);
    }
  }

  /// Closes the membership stream (tests).
  Future<void> dispose() async {
    await _membershipController.close();
  }

  @override
  Future<List<String>> getOrderedIds() => _local.readOrderedIds();

  @override
  Future<bool> isWatched(String coinId) async {
    final ids = await _local.readOrderedIds();
    return ids.contains(coinId);
  }

  @override
  Future<void> setWatched(String coinId, {required bool watched}) async {
    final ids = await _local.readOrderedIds();
    if (watched) {
      if (ids.contains(coinId)) {
        return;
      }
      await _local.writeOrderedIds([...ids, coinId]);
      _notifyMembershipChanged();
      return;
    }
    if (!ids.contains(coinId)) {
      return;
    }
    await _local.writeOrderedIds(
      ids.where((id) => id != coinId).toList(growable: false),
    );
    _notifyMembershipChanged();
  }

  @override
  Future<void> reorder({required int oldIndex, required int newIndex}) async {
    final ids = await _local.readOrderedIds();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex >= ids.length) {
      return;
    }
    final next = List<String>.from(ids);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    await _local.writeOrderedIds(next);
    _notifyMembershipChanged();
  }

  @override
  Future<void> insertAt({required String coinId, required int index}) async {
    final ids = await _local.readOrderedIds();
    if (ids.contains(coinId)) {
      return;
    }
    final next = List<String>.from(ids);
    final clamped = index.clamp(0, next.length);
    next.insert(clamped, coinId);
    await _local.writeOrderedIds(next);
    _notifyMembershipChanged();
  }

  @override
  Future<Result<WatchlistSnapshot>> loadWatchlist() {
    return _buildSnapshot(forceRefresh: false);
  }

  @override
  Future<Result<WatchlistSnapshot>> refreshWatchlist() {
    return _buildSnapshot(forceRefresh: true);
  }

  Future<Result<WatchlistSnapshot>> _buildSnapshot({
    required bool forceRefresh,
  }) async {
    final ids = await _local.readOrderedIds();
    if (ids.isEmpty) {
      return const Success(WatchlistSnapshot(entries: []));
    }

    final marketsResult = forceRefresh
        ? await _marketsRepository.refreshMarkets()
        : await _marketsRepository.loadMarkets();

    List<MarketCoin> topCoins = const [];
    DateTime? fetchedAt;
    var marketsStale = false;
    AppFailure? sideError;

    switch (marketsResult) {
      case Success(:final value, :final isStale, :final refreshError):
        topCoins = value.coins;
        fetchedAt = value.fetchedAt;
        marketsStale = isStale;
        sideError = refreshError;
      case Failure(:final error):
        if (!forceRefresh) {
          return Failure(error);
        }
        final online = await _connectivity.isOnline;
        if (!online) {
          return const Failure(NetworkFailure(offline: true));
        }
        return Failure(error);
    }

    final byId = {for (final c in topCoins) c.id: c};
    final missing = ids.where((id) => !byId.containsKey(id)).toList();

    var supplementalStale = false;
    if (missing.isNotEmpty) {
      final supplemental = forceRefresh
          ? await _supplementalMarkets.refreshByIds(missing)
          : await _supplementalMarkets.fetchByIds(missing);
      switch (supplemental) {
        case Success(:final value, :final isStale, :final refreshError):
          for (final coin in value) {
            byId[coin.id] = coin;
          }
          supplementalStale = isStale;
          sideError ??= refreshError;
        case Failure(:final error):
          if (byId.isEmpty) {
            return Failure(error);
          }
          marketsStale = true;
          sideError = error;
      }
    }

    final entries = <WatchlistEntry>[];
    for (final id in ids) {
      final coin = byId[id];
      if (coin != null) {
        entries.add(WatchlistEntry(coinId: id, coin: coin));
      } else {
        entries.add(WatchlistEntry.unavailable(coinId: id));
      }
    }

    final snapshot = WatchlistSnapshot(entries: entries, fetchedAt: fetchedAt);
    if (marketsStale || supplementalStale) {
      return Success(snapshot, isStale: true, refreshError: sideError);
    }
    return Success(snapshot);
  }
}
