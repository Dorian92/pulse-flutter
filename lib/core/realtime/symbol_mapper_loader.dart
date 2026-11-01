import 'dart:developer' as developer;

import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/storage/cache_store.dart';

/// Loads Binance `exchangeInfo` into [SymbolMapper] with long-lived cache.
class SymbolMapperLoader {
  /// Creates a loader.
  SymbolMapperLoader({
    required ApiClient apiClient,
    required CacheStore cacheStore,
    required SymbolMapper symbolMapper,
    this.cacheKey = 'symbol_mapper_exchange_info_v1',
    this.cacheTtl = const Duration(days: 7),
  }) : _apiClient = apiClient,
       _cacheStore = cacheStore,
       _symbolMapper = symbolMapper;

  final ApiClient _apiClient;
  final CacheStore _cacheStore;
  final SymbolMapper _symbolMapper;

  /// Hive/cache key for the parsed base-asset map JSON.
  final String cacheKey;

  /// TTL for cached exchange info payload.
  final Duration cacheTtl;

  static const int _schemaVersion = 1;

  /// Ensures [SymbolMapper] has exchange-derived USDT pairs (no-op when cached).
  Future<Result<bool>> warmUp() async {
    final cached = await _cacheStore.readFresh(
      key: cacheKey,
      schemaVersion: _schemaVersion,
    );
    if (cached != null) {
      final generationBefore = _symbolMapper.generation;
      _applyPayload(cached);
      if (_symbolMapper.generation > generationBefore) {
        return const Success(true);
      }
    }

    final remote = await _apiClient.getBinanceJson<Map<String, dynamic>>(
      path: '/api/v3/exchangeInfo',
      queryParameters: const {'permissions': 'SPOT'},
      decode: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('exchangeInfo map expected');
        }
        return json;
      },
    );

    switch (remote) {
      case Success(:final value):
        final baseMap = _parseExchangeInfo(value);
        await _cacheStore.writeJson(
          key: cacheKey,
          payload: {'bases': baseMap},
          ttl: cacheTtl,
          schemaVersion: _schemaVersion,
        );
        _symbolMapper.applyExchangeBaseAssets(baseMap);
        return const Success(true);
      case Failure(:final error):
        final stale = await _cacheStore.readStale(
          key: cacheKey,
          schemaVersion: _schemaVersion,
        );
        if (stale != null) {
          _applyPayload(stale);
          developer.log(
            'SymbolMapperLoader: remote failed; using stale exchangeInfo cache',
            name: 'SymbolMapperLoader',
          );
          return const Success(true, isStale: true);
        }
        return Failure(error);
    }
  }

  void _applyPayload(Map<String, dynamic> payload) {
    final bases = payload['bases'] as Map<String, dynamic>?;
    if (bases == null) {
      developer.log(
        'SymbolMapperLoader: corrupt cache payload (missing bases)',
        name: 'SymbolMapperLoader',
      );
      return;
    }
    _symbolMapper.applyExchangeBaseAssets(
      bases.map((key, value) => MapEntry(key, value as String)),
    );
  }

  /// Parses TRADING USDT pairs into `{ BASE_ASSET: SYMBOL }`.
  static Map<String, String> _parseExchangeInfo(Map<String, dynamic> json) {
    final symbols = json['symbols'] as List<dynamic>? ?? [];
    final map = <String, String>{};
    for (final raw in symbols) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      if (raw['status'] != 'TRADING') {
        continue;
      }
      if (raw['quoteAsset'] != 'USDT') {
        continue;
      }
      final base = raw['baseAsset'] as String?;
      final symbol = raw['symbol'] as String?;
      if (base == null || symbol == null) {
        continue;
      }
      map.putIfAbsent(base, () => symbol);
    }
    return map;
  }
}
