import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_first.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/data_sources/markets_local_data_source.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';
import 'package:pulse/markets/repository/markets_repository.dart';

/// Cache-first markets repository.
class MarketsRepositoryImpl implements MarketsRepository {
  /// Creates the repository.
  MarketsRepositoryImpl({
    required MarketsRemoteDataSource remote,
    required MarketsLocalDataSource local,
    required ConnectivityService connectivity,
    this.vsCurrency = 'eur',
  }) : _remote = remote,
       _local = local,
       _connectivity = connectivity;

  final MarketsRemoteDataSource _remote;
  final MarketsLocalDataSource _local;
  final ConnectivityService _connectivity;

  /// Display / cache currency segment.
  final String vsCurrency;

  String get _cacheKey => _local.cacheKeyFor(vsCurrency: vsCurrency);

  @override
  Future<Result<MarketsSnapshot>> loadMarkets() {
    return fetchCacheFirst<MarketsSnapshot>(
      cache: _local.cacheStore,
      connectivity: _connectivity,
      cacheKey: _cacheKey,
      ttl: MarketsLocalDataSource.ttl,
      schemaVersion: MarketsLocalDataSource.schemaVersion,
      fetchRemote: _remote.fetchMarkets,
      decode: MarketsSnapshot.fromJson,
      encode: (value) => value.toJson(),
    );
  }

  @override
  Future<Result<MarketsSnapshot>> refreshMarkets() async {
    final online = await _connectivity.isOnline;
    if (!online) {
      return _cachedStaleSuccess(const NetworkFailure(offline: true));
    }

    final remote = await _remote.fetchMarkets();
    switch (remote) {
      case Success(:final value):
        await _local.writeSnapshot(cacheKey: _cacheKey, snapshot: value);
        return Success(value);
      case Failure(:final error):
        return _cachedStaleSuccess(error);
    }
  }

  Future<Result<MarketsSnapshot>> _cachedStaleSuccess(AppFailure cause) async {
    final cached = await _readCachedSnapshot();
    if (cached != null) {
      return Success(cached, isStale: true, refreshError: cause);
    }
    return Failure<MarketsSnapshot>(cause);
  }

  Future<MarketsSnapshot?> _readCachedSnapshot() async {
    final json = await _local.readAnyJson(_cacheKey);
    if (json == null) {
      return null;
    }
    return MarketsSnapshot.fromJson(json);
  }
}
