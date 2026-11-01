import 'package:pulse/core/error/result.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';

/// Watchlist order and enriched coin rows.
abstract class WatchlistRepository {
  /// Ordered coin ids (local source of truth).
  Future<List<String>> getOrderedIds();

  /// Whether [coinId] is saved.
  Future<bool> isWatched(String coinId);

  /// Adds or removes [coinId] at end when adding.
  Future<void> setWatched(String coinId, {required bool watched});

  /// Moves item from [oldIndex] to [newIndex].
  Future<void> reorder({required int oldIndex, required int newIndex});

  /// Inserts [coinId] at [index] (undo).
  Future<void> insertAt({required String coinId, required int index});

  /// Cache-first load of watchlist market rows.
  Future<Result<WatchlistSnapshot>> loadWatchlist();

  /// Pull-to-refresh / bypass TTL for supplemental ids fetch.
  Future<Result<WatchlistSnapshot>> refreshWatchlist();
}
