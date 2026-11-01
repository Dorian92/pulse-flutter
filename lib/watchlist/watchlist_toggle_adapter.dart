import 'package:pulse/coin_detail/watchlist/watchlist_toggle.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';

/// [WatchlistToggle] backed by [WatchlistRepository].
class WatchlistRepositoryToggle implements WatchlistToggle {
  /// Creates a toggle adapter.
  WatchlistRepositoryToggle(this._repository);

  final WatchlistRepository _repository;

  @override
  Future<bool> isWatched(String coinId) => _repository.isWatched(coinId);

  @override
  Future<void> setWatched(String coinId, {required bool watched}) {
    return _repository.setWatched(coinId, watched: watched);
  }
}
