import 'package:equatable/equatable.dart';
import 'package:pulse/markets/models/market_coin.dart';

/// Watchlist rows in user order with staleness metadata.
class WatchlistSnapshot extends Equatable {
  /// Creates a snapshot.
  const WatchlistSnapshot({required this.coins, this.fetchedAt});

  /// Ordered coins (may be empty).
  final List<MarketCoin> coins;

  /// Latest REST merge timestamp when available.
  final DateTime? fetchedAt;

  @override
  List<Object?> get props => [coins, fetchedAt];
}

/// Pending undo after swipe remove.
class WatchlistUndoPayload extends Equatable {
  /// Creates undo metadata.
  const WatchlistUndoPayload({
    required this.coinId,
    required this.index,
    required this.coin,
  });

  /// Removed coin id.
  final String coinId;

  /// Index in list before removal.
  final int index;

  /// Row data to restore without refetch.
  final MarketCoin coin;

  @override
  List<Object?> get props => [coinId, index, coin];
}
