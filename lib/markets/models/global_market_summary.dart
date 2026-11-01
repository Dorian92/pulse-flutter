import 'package:equatable/equatable.dart';

/// Global crypto market cap summary for [MarketSummaryCard].
class GlobalMarketSummary extends Equatable {
  /// Creates global summary values.
  const GlobalMarketSummary({
    required this.totalMarketCapEur,
    required this.marketCapChangePercent24h,
  });

  /// Parses from JSON map.
  factory GlobalMarketSummary.fromJson(Map<String, dynamic> json) {
    return GlobalMarketSummary(
      totalMarketCapEur: (json['totalMarketCapEur'] as num?)?.toDouble() ?? 0,
      marketCapChangePercent24h:
          (json['marketCapChangePercent24h'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Total market cap in EUR.
  final double totalMarketCapEur;

  /// 24h global market cap change percentage.
  final double marketCapChangePercent24h;

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
