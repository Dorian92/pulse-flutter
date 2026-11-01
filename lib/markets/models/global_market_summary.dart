import 'package:equatable/equatable.dart';

/// Global crypto market cap summary for [MarketSummaryCard].
class GlobalMarketSummary extends Equatable {
  /// Creates global summary values.
  const GlobalMarketSummary({
    required this.marketCapChangePercent24h,
    this.totalMarketCapEur,
  });

  /// Parses from JSON map.
  factory GlobalMarketSummary.fromJson(Map<String, dynamic> json) {
    final cap = json['totalMarketCapEur'];
    return GlobalMarketSummary(
      totalMarketCapEur: cap == null ? null : (cap as num).toDouble(),
      marketCapChangePercent24h:
          (json['marketCapChangePercent24h'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Total market cap in the user's display currency (CoinGecko `vs_currency`
  /// key). Field name is historical; value is USD when display currency is USD.
  final double? totalMarketCapEur;

  /// 24h global market cap change percentage.
  final double marketCapChangePercent24h;

  /// Whether the summary card can show a market cap value.
  bool get hasMarketCap => totalMarketCapEur != null;

  /// Serializes for cache.
  Map<String, dynamic> toJson() {
    return {
      'totalMarketCapEur': totalMarketCapEur,
      'marketCapChangePercent24h': marketCapChangePercent24h,
    };
  }

  @override
  List<Object?> get props => [totalMarketCapEur, marketCapChangePercent24h];
}
