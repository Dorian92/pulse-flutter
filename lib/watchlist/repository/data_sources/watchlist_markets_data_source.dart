import 'package:pulse/core/util/stable_hash.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

/// Fetches CoinGecko `/coins/markets` rows for explicit ids with TTL cache.
class WatchlistMarketsDataSource {
  /// Creates a data source.
  WatchlistMarketsDataSource({
    required ApiClient apiClient,
    required SymbolMapper symbolMapper,
    required CacheStore cacheStore,
    required SettingsRepository settingsRepository,
  }) : _apiClient = apiClient,
       _symbolMapper = symbolMapper,
       _cache = cacheStore,
       _settingsRepository = settingsRepository;

  static const int schemaVersion = 1;
  static const Duration ttl = Duration(minutes: 10);

  final ApiClient _apiClient;
  final SymbolMapper _symbolMapper;
  final CacheStore _cache;
  final SettingsRepository _settingsRepository;

  String get _vsCurrency =>
      _settingsRepository.current.displayCurrency.coingeckoCode;

  String _cacheKeyFor(List<String> ids) {
    final hash = stableHashForSortedIds(ids);
    return 'markets:by_ids:$_vsCurrency:$hash';
  }

  /// Loads coins for [ids] using cache-first TTL.
  Future<Result<List<MarketCoin>>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const Success([]);
    }
    final cacheKey = _cacheKeyFor(ids);
    final fresh = await _cache.readFresh(
      key: cacheKey,
      schemaVersion: schemaVersion,
    );
    if (fresh != null) {
      return Success(_decodeCoins(fresh));
    }

    final remote = await _fetchRemote(ids);
    switch (remote) {
      case Success(:final value):
        await _cache.writeJson(
          key: cacheKey,
          payload: {'coins': value.map((c) => c.toJson()).toList()},
          ttl: ttl,
          schemaVersion: schemaVersion,
        );
        return Success(value);
      case Failure(:final error):
        final stale = await _cache.readStale(
          key: cacheKey,
          schemaVersion: schemaVersion,
        );
        if (stale != null) {
          return Success(
            _decodeCoins(stale),
            isStale: true,
            refreshError: error,
          );
        }
        return Failure(error);
    }
  }

  /// Bypasses TTL and refreshes cache when online.
  Future<Result<List<MarketCoin>>> refreshByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const Success([]);
    }
    final remote = await _fetchRemote(ids);
    switch (remote) {
      case Success(:final value):
        final cacheKey = _cacheKeyFor(ids);
        await _cache.writeJson(
          key: cacheKey,
          payload: {'coins': value.map((c) => c.toJson()).toList()},
          ttl: ttl,
          schemaVersion: schemaVersion,
        );
        return Success(value);
      case Failure(:final error):
        final cacheKey = _cacheKeyFor(ids);
        final stale = await _cache.readStale(
          key: cacheKey,
          schemaVersion: schemaVersion,
        );
        if (stale != null) {
          return Success(
            _decodeCoins(stale),
            isStale: true,
            refreshError: error,
          );
        }
        return Failure(error);
    }
  }

  Future<Result<List<MarketCoin>>> _fetchRemote(List<String> ids) {
    return _apiClient.getCoinGeckoJson<List<MarketCoin>>(
      path: '/coins/markets',
      queryParameters: {
        'vs_currency': _vsCurrency,
        'ids': ids.join(','),
        'sparkline': 'true',
        'price_change_percentage': '24h',
      },
      decode: (json) {
        if (json is! List) {
          throw const FormatException('Expected list for /coins/markets ids');
        }
        return json
            .map(
              (raw) => parseMarketCoinFromApi(
                raw as Map<String, dynamic>,
                symbolMapper: _symbolMapper,
              ),
            )
            .toList(growable: false);
      },
    );
  }

  List<MarketCoin> _decodeCoins(Map<String, dynamic> payload) {
    final raw = payload['coins'];
    if (raw is! List) {
      return const [];
    }
    return raw
        .map(
          (item) => MarketCoin.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }
}
