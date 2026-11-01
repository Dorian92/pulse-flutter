import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/widgets/period_selector.dart';

/// Coin detail and chart loading.
abstract class CoinDetailRepository {
  /// Cache-first metadata for [coinId].
  Future<Result<CoinDetail>> loadDetail(String coinId);

  /// Cache-first chart for [coinId] and [range].
  Future<Result<PriceChartSeries>> loadChart({
    required String coinId,
    required ChartPeriod range,
  });

  /// Bypass TTL for metadata when online.
  Future<Result<CoinDetail>> refreshDetail(String coinId);

  /// Bypass TTL for chart when online.
  Future<Result<PriceChartSeries>> refreshChart({
    required String coinId,
    required ChartPeriod range,
  });
}
