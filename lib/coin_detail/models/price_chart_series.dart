import 'package:equatable/equatable.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/core/widgets/period_selector.dart';

/// Origin of chart samples (for debugging and tests).
enum ChartDataSource {
  /// Binance klines converted to EUR.
  binanceKlines,

  /// CoinGecko `/market_chart` in EUR.
  coinGeckoMarketChart,
}

/// Cached chart payload for one coin and period.
class PriceChartSeries extends Equatable {
  /// Creates a series.
  const PriceChartSeries({
    required this.points,
    required this.range,
    required this.source,
    required this.fetchedAt,
  });

  /// Ordered samples (oldest first).
  final List<ChartPoint> points;

  /// UI range this series represents.
  final ChartPeriod range;

  /// Where the samples were loaded from.
  final ChartDataSource source;

  /// When the series was fetched (UTC).
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'range': range.name,
    'source': source.name,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory PriceChartSeries.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>;
    return PriceChartSeries(
      points: rawPoints
          .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      range: ChartPeriod.values.byName(json['range'] as String),
      source: ChartDataSource.values.byName(json['source'] as String),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [points, range, source, fetchedAt];
}
