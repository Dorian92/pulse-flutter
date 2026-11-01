import 'package:equatable/equatable.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';

/// Cached markets payload: list + global summary + fetch timestamp.
class MarketsSnapshot extends Equatable {
  /// Creates a snapshot.
  const MarketsSnapshot({
    required this.coins,
    required this.global,
    required this.fetchedAt,
  });

  /// Parses envelope payload JSON.
  factory MarketsSnapshot.fromJson(Map<String, dynamic> json) {
    final coinsRaw = json['coins'] as List<dynamic>? ?? const [];
    return MarketsSnapshot(
      coins: coinsRaw
          .map((e) => MarketCoin.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      global: GlobalMarketSummary.fromJson(
        Map<String, dynamic>.from(json['global'] as Map? ?? const {}),
      ),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  /// Top coins by market cap.
  final List<MarketCoin> coins;

  /// Global summary for the header card.
  final GlobalMarketSummary global;

  /// When this snapshot was fetched or read from cache (UTC).
  final DateTime fetchedAt;

  /// Serializes for Hive.
  Map<String, dynamic> toJson() {
    return {
      'coins': coins.map((c) => c.toJson()).toList(),
      'global': global.toJson(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [coins, global, fetchedAt];
}
