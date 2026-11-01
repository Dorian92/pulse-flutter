import 'package:pulse/coin_detail/models/chart_range_config.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/widgets/period_selector.dart';

/// Hive-backed cache for coin detail metadata and chart series.
class CoinDetailLocalDataSource {
  /// Creates a local data source.
  CoinDetailLocalDataSource({required CacheStore cacheStore})
    : _cache = cacheStore;

  static const int schemaVersion = 1;
  static const Duration metadataTtl = Duration(hours: 24);

  final CacheStore _cache;

  /// Underlying TTL store (for [fetchCacheFirst]).
  CacheStore get cacheStore => _cache;

  /// Metadata cache key.
  String metadataKeyFor({required String coinId, String vsCurrency = 'eur'}) {
    return 'coin:$coinId:meta:$vsCurrency';
  }

  /// Chart cache key for [range].
  String chartKeyFor({
    required String coinId,
    required ChartPeriod range,
    String vsCurrency = 'eur',
  }) {
    return 'chart:$coinId:${range.cacheSegment}:$vsCurrency';
  }

  Duration chartTtlFor(ChartPeriod range) => range.chartTtl;

  Future<Map<String, dynamic>?> readAnyJson(String cacheKey) async {
    final fresh = await _cache.readFresh(
      key: cacheKey,
      schemaVersion: schemaVersion,
    );
    if (fresh != null) {
      return fresh;
    }
    return _cache.readStale(key: cacheKey, schemaVersion: schemaVersion);
  }

  Future<void> writeMetadata({
    required String cacheKey,
    required CoinDetail detail,
  }) {
    return _cache.writeJson(
      key: cacheKey,
      payload: detail.toJson(),
      ttl: metadataTtl,
      schemaVersion: schemaVersion,
    );
  }

  Future<void> writeChart({
    required String cacheKey,
    required PriceChartSeries series,
    required ChartPeriod range,
  }) {
    return _cache.writeJson(
      key: cacheKey,
      payload: series.toJson(),
      ttl: range.chartTtl,
      schemaVersion: schemaVersion,
    );
  }
}
