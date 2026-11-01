/// Persists watchlist membership (stub until step 7).
abstract class WatchlistToggle {
  /// Whether [coinId] is on the watchlist.
  Future<bool> isWatched(String coinId);

  /// Adds or removes [coinId] from the watchlist.
  Future<void> setWatched(String coinId, {required bool watched});
}

/// In-memory watchlist for step 6 (replaced in step 7).
class InMemoryWatchlistToggle implements WatchlistToggle {
  /// Creates an empty store.
  InMemoryWatchlistToggle();

  final Set<String> _ids = {};

  @override
  Future<bool> isWatched(String coinId) async => _ids.contains(coinId);

  @override
  Future<void> setWatched(String coinId, {required bool watched}) async {
    if (watched) {
      _ids.add(coinId);
    } else {
      _ids.remove(coinId);
    }
  }
}
