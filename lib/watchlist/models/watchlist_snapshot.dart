import 'package:equatable/equatable.dart';
import 'package:pulse/markets/models/market_coin.dart';

/// One ordered watchlist row: market data or unavailable placeholder.
class WatchlistEntry extends Equatable {
  /// Creates an entry with loaded [coin] data.
  const WatchlistEntry({required this.coinId, required this.coin});

  /// Creates a placeholder when market data could not be loaded.
  const WatchlistEntry.unavailable({required this.coinId}) : coin = null;

  /// CoinGecko id (persisted order key).
  final String coinId;

  /// Row payload when CoinGecko returned data; null for unavailable tiles.
  final MarketCoin? coin;

  /// True when neither markets cache nor supplemental fetch returned this id.
  bool get isUnavailable => coin == null;

  @override
  List<Object?> get props => [coinId, coin];
}

/// Watchlist rows in user order with staleness metadata.
class WatchlistSnapshot extends Equatable {
  /// Creates a snapshot.
  const WatchlistSnapshot({required this.entries, this.fetchedAt});

  /// Ordered entries (includes unavailable placeholders).
  final List<WatchlistEntry> entries;

  /// Latest REST merge timestamp when available.
  final DateTime? fetchedAt;

  /// Loaded coins only (live subscription / tests).
  List<MarketCoin> get coins => entries
      .where((entry) => entry.coin != null)
      .map((entry) => entry.coin!)
      .toList(growable: false);

  @override
  List<Object?> get props => [entries, fetchedAt];
}

/// Pending undo after swipe remove.
class WatchlistUndoPayload extends Equatable {
  /// Creates undo metadata.
  const WatchlistUndoPayload({
    required this.coinId,
    required this.index,
    required this.entry,
  });

  /// Removed coin id.
  final String coinId;

  /// Index in list before removal.
  final int index;

  /// Row data to restore without refetch.
  final WatchlistEntry entry;

  @override
  List<Object?> get props => [coinId, index, entry];
}
