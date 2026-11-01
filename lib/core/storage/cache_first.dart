import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_store.dart';

/// Cache-first load: fresh cache, else network, else stale cache with [Success.isStale].
///
/// A fresh cache hit returns immediately and does **not** trigger a background
/// network refresh; repositories can implement stale-while-revalidate separately.
Future<Result<T>> fetchCacheFirst<T>({
  required CacheStore cache,
  required ConnectivityService connectivity,
  required String cacheKey,
  required Duration ttl,
  required int schemaVersion,
  required Future<Result<T>> Function() fetchRemote,
  required T Function(Map<String, dynamic> json) decode,
  required Map<String, dynamic> Function(T value) encode,
}) async {
  try {
    final freshJson = await cache.readFresh(
      key: cacheKey,
      schemaVersion: schemaVersion,
    );
    if (freshJson != null) {
      return Success(decode(freshJson));
    }

    final online = await connectivity.isOnline;
    if (!online) {
      final staleJson = await cache.readStale(
        key: cacheKey,
        schemaVersion: schemaVersion,
      );
      if (staleJson != null) {
        return Success(decode(staleJson), isStale: true);
      }
      return const Failure(NetworkFailure(offline: true));
    }

    final remote = await fetchRemote();
    switch (remote) {
      case Success(:final value):
        await cache.writeJson(
          key: cacheKey,
          payload: encode(value),
          ttl: ttl,
          schemaVersion: schemaVersion,
        );
        return Success(value);
      case Failure(:final error):
        final staleJson = await cache.readStale(
          key: cacheKey,
          schemaVersion: schemaVersion,
        );
        if (staleJson != null) {
          return Success(decode(staleJson), isStale: true);
        }
        return Failure<T>(error);
    }
  } on Object catch (error) {
    return Failure(CacheFailure(cause: error));
  }
}
