import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';

/// Hive-backed cache for [MarketsSnapshot].
class MarketsLocalDataSource {
  /// Creates a local data source.
  MarketsLocalDataSource({required CacheStore cacheStore})
    : _cache = cacheStore;

  static const int schemaVersion = 1;
  static const Duration ttl = Duration(minutes: 10);

  final CacheStore _cache;

  /// Underlying TTL store (for [fetchCacheFirst]).
  CacheStore get cacheStore => _cache;

  /// Cache key for the markets list payload.
  String cacheKeyFor({required String vsCurrency}) => 'markets:$vsCurrency';

  /// Reads fresh JSON payload or null.
  Future<Map<String, dynamic>?> readFreshJson(String cacheKey) {
    return _cache.readFresh(key: cacheKey, schemaVersion: schemaVersion);
  }

  /// Reads stale JSON payload or null.
  Future<Map<String, dynamic>?> readStaleJson(String cacheKey) {
    return _cache.readStale(key: cacheKey, schemaVersion: schemaVersion);
  }

  /// Reads fresh JSON if valid, otherwise any stale envelope payload.
  Future<Map<String, dynamic>?> readAnyJson(String cacheKey) async {
    final fresh = await readFreshJson(cacheKey);
    if (fresh != null) {
      return fresh;
    }
    return readStaleJson(cacheKey);
  }

  /// Persists [snapshot] under [cacheKey].
  Future<void> writeSnapshot({
    required String cacheKey,
    required MarketsSnapshot snapshot,
  }) {
    return _cache.writeJson(
      key: cacheKey,
      payload: snapshot.toJson(),
      ttl: ttl,
      schemaVersion: schemaVersion,
    );
  }
}
