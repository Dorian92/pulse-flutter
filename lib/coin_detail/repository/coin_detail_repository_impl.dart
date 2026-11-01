import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_local_data_source.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_first.dart';
import 'package:pulse/core/widgets/period_selector.dart';

/// Cache-first coin detail repository.
class CoinDetailRepositoryImpl implements CoinDetailRepository {
  /// Creates the repository.
  CoinDetailRepositoryImpl({
    required CoinDetailRemoteDataSource remote,
    required CoinDetailLocalDataSource local,
    required ConnectivityService connectivity,
    this.vsCurrency = 'eur',
  }) : _remote = remote,
       _local = local,
       _connectivity = connectivity;

  final CoinDetailRemoteDataSource _remote;
  final CoinDetailLocalDataSource _local;
  final ConnectivityService _connectivity;

  /// Display / cache currency segment.
  final String vsCurrency;

  String _metadataKey(String coinId) =>
      _local.metadataKeyFor(coinId: coinId, vsCurrency: vsCurrency);

  String _chartKey(String coinId, ChartPeriod range) =>
      _local.chartKeyFor(coinId: coinId, range: range, vsCurrency: vsCurrency);

  Future<String?> _resolveBinanceSymbol({
    required String coinId,
    String? binanceSymbol,
  }) async {
    if (binanceSymbol != null) {
      return binanceSymbol;
    }
    return (await _readCachedDetail(coinId))?.binanceSymbol;
  }

  @override
  Future<Result<CoinDetail>> loadDetail(String coinId) {
    final cacheKey = _metadataKey(coinId);
    return fetchCacheFirst<CoinDetail>(
      cache: _local.cacheStore,
      connectivity: _connectivity,
      cacheKey: cacheKey,
      ttl: CoinDetailLocalDataSource.metadataTtl,
      schemaVersion: CoinDetailLocalDataSource.schemaVersion,
      fetchRemote: () => _remote.fetchDetail(coinId),
      decode: CoinDetail.fromJson,
      encode: (value) => value.toJson(),
    );
  }

  @override
  Future<Result<PriceChartSeries>> loadChart({
    required String coinId,
    required ChartPeriod range,
    String? binanceSymbol,
  }) {
    final cacheKey = _chartKey(coinId, range);
    final resolvedSymbol = binanceSymbol;
    return fetchCacheFirst<PriceChartSeries>(
      cache: _local.cacheStore,
      connectivity: _connectivity,
      cacheKey: cacheKey,
      ttl: _local.chartTtlFor(range),
      schemaVersion: CoinDetailLocalDataSource.schemaVersion,
      fetchRemote: () async {
        final symbol = await _resolveBinanceSymbol(
          coinId: coinId,
          binanceSymbol: resolvedSymbol,
        );
        return _remote.fetchChart(
          coinId: coinId,
          range: range,
          binanceSymbol: symbol,
        );
      },
      decode: PriceChartSeries.fromJson,
      encode: (value) => value.toJson(),
    );
  }

  @override
  Future<Result<CoinDetail>> refreshDetail(String coinId) async {
    final online = await _connectivity.isOnline;
    if (!online) {
      return _cachedDetailStale(const NetworkFailure(offline: true), coinId);
    }
    final remote = await _remote.fetchDetail(coinId);
    switch (remote) {
      case Success(:final value):
        await _local.writeMetadata(
          cacheKey: _metadataKey(coinId),
          detail: value,
        );
        return Success(value);
      case Failure(:final error):
        return _cachedDetailStale(error, coinId);
    }
  }

  @override
  Future<Result<PriceChartSeries>> refreshChart({
    required String coinId,
    required ChartPeriod range,
    String? binanceSymbol,
  }) async {
    final online = await _connectivity.isOnline;
    if (!online) {
      return _cachedChartStale(
        const NetworkFailure(offline: true),
        coinId,
        range,
      );
    }
    final symbol = await _resolveBinanceSymbol(
      coinId: coinId,
      binanceSymbol: binanceSymbol,
    );
    final remote = await _remote.fetchChart(
      coinId: coinId,
      range: range,
      binanceSymbol: symbol,
    );
    switch (remote) {
      case Success(:final value):
        await _local.writeChart(
          cacheKey: _chartKey(coinId, range),
          series: value,
          range: range,
        );
        return Success(value);
      case Failure(:final error):
        return _cachedChartStale(error, coinId, range);
    }
  }

  Future<Result<CoinDetail>> _cachedDetailStale(
    AppFailure cause,
    String coinId,
  ) async {
    final cached = await _readCachedDetail(coinId);
    if (cached != null) {
      return Success(cached, isStale: true, refreshError: cause);
    }
    return Failure<CoinDetail>(cause);
  }

  Future<Result<PriceChartSeries>> _cachedChartStale(
    AppFailure cause,
    String coinId,
    ChartPeriod range,
  ) async {
    final cached = await _readCachedChart(coinId, range);
    if (cached != null) {
      return Success(cached, isStale: true, refreshError: cause);
    }
    return Failure<PriceChartSeries>(cause);
  }

  Future<CoinDetail?> _readCachedDetail(String coinId) async {
    final json = await _local.readAnyJson(_metadataKey(coinId));
    if (json == null) {
      return null;
    }
    return CoinDetail.fromJson(json);
  }

  Future<PriceChartSeries?> _readCachedChart(
    String coinId,
    ChartPeriod range,
  ) async {
    final json = await _local.readAnyJson(_chartKey(coinId, range));
    if (json == null) {
      return null;
    }
    return PriceChartSeries.fromJson(json);
  }
}
