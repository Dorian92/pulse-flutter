import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/chart_range_config.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/time/clock.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

/// Fetches coin detail metadata and chart series from CoinGecko and Binance.
class CoinDetailRemoteDataSource {
  /// Creates a remote data source.
  CoinDetailRemoteDataSource({
    required ApiClient apiClient,
    required SymbolMapper symbolMapper,
    required Clock clock,
    required SettingsRepository settingsRepository,
  }) : _apiClient = apiClient,
       _symbolMapper = symbolMapper,
       _clock = clock,
       _settingsRepository = settingsRepository;

  final ApiClient _apiClient;
  final SymbolMapper _symbolMapper;
  final Clock _clock;
  final SettingsRepository _settingsRepository;

  /// Quote currency for CoinGecko calls.
  String get vsCurrency =>
      _settingsRepository.current.displayCurrency.coingeckoCode;

  /// Loads metadata for [coinId].
  Future<Result<CoinDetail>> fetchDetail(String coinId) async {
    return _apiClient.getCoinGeckoJson<CoinDetail>(
      path: '/coins/$coinId',
      queryParameters: {
        'localization': 'false',
        'tickers': 'false',
        'market_data': 'true',
        'community_data': 'false',
        'developer_data': 'false',
      },
      decode: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Expected map for /coins/{id}');
        }
        return parseCoinDetailFromApi(
          json,
          coinId: coinId,
          symbolMapper: _symbolMapper,
          fetchedAt: _clock.now().toUtc(),
          vsCurrency: vsCurrency,
        );
      },
    );
  }

  /// Loads chart data for [coinId] and [range].
  Future<Result<PriceChartSeries>> fetchChart({
    required String coinId,
    required ChartPeriod range,
    String? binanceSymbol,
  }) async {
    if (binanceSymbol != null) {
      final binanceResult = await _fetchBinanceChart(
        binanceSymbol: binanceSymbol,
        range: range,
      );
      if (binanceResult case Success()) {
        return binanceResult;
      }
    }
    return _fetchCoinGeckoChart(coinId: coinId, range: range);
  }

  Future<Result<PriceChartSeries>> _fetchBinanceChart({
    required String binanceSymbol,
    required ChartPeriod range,
  }) async {
    final eurRateResult = await _fetchEurUsdtRate();
    if (eurRateResult case Failure(:final error)) {
      return Failure(error);
    }
    final eurUsdt = (eurRateResult as Success<double>).value;
    if (eurUsdt <= 0) {
      return const Failure(ServerFailure());
    }
    final quoteIsUsd = vsCurrency == 'usd';

    final params = range.binanceKlineParams;
    final klinesResult = await _apiClient.getBinanceJson<List<dynamic>>(
      path: '/api/v3/klines',
      queryParameters: {
        'symbol': binanceSymbol,
        'interval': params.$1,
        'limit': '${params.$2}',
      },
      decode: (json) {
        if (json is! List) {
          throw const FormatException('Expected list for klines');
        }
        return json;
      },
    );

    switch (klinesResult) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        final points = <ChartPoint>[];
        for (final raw in value) {
          if (raw is! List || raw.length < 5) {
            continue;
          }
          final openTimeMs = raw[0] as int;
          final closeUsdt = double.parse(raw[4] as String);
          final displayPrice = quoteIsUsd ? closeUsdt : closeUsdt / eurUsdt;
          points.add(
            ChartPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                openTimeMs,
                isUtc: true,
              ),
              priceEur: displayPrice,
            ),
          );
        }
        if (points.isEmpty) {
          return const Failure(ServerFailure());
        }
        return Success(
          PriceChartSeries(
            points: points,
            range: range,
            source: ChartDataSource.binanceKlines,
            fetchedAt: _clock.now().toUtc(),
          ),
        );
    }
  }

  Future<Result<PriceChartSeries>> _fetchCoinGeckoChart({
    required String coinId,
    required ChartPeriod range,
  }) async {
    final days = range.coinGeckoDays;
    return _apiClient.getCoinGeckoJson<PriceChartSeries>(
      path: '/coins/$coinId/market_chart',
      queryParameters: {'vs_currency': vsCurrency, 'days': '$days'},
      decode: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Expected map for market_chart');
        }
        final prices = json['prices'] as List<dynamic>? ?? [];
        final points = prices
            .map((entry) {
              if (entry is! List || entry.length < 2) {
                return null;
              }
              return ChartPoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (entry[0] as num).toInt(),
                  isUtc: true,
                ),
                priceEur: (entry[1] as num).toDouble(),
              );
            })
            .whereType<ChartPoint>()
            .toList(growable: false);
        if (points.isEmpty) {
          throw const FormatException('Empty chart prices');
        }
        return PriceChartSeries(
          points: points,
          range: range,
          source: ChartDataSource.coinGeckoMarketChart,
          fetchedAt: _clock.now().toUtc(),
        );
      },
    );
  }

  Future<Result<double>> _fetchEurUsdtRate() {
    return _apiClient.getBinanceJson<double>(
      path: '/api/v3/ticker/price',
      queryParameters: {'symbol': 'EURUSDT'},
      decode: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Expected map for ticker price');
        }
        return double.parse(json['price'] as String);
      },
    );
  }
}

/// Parses CoinGecko `/coins/{id}` into [CoinDetail].
CoinDetail parseCoinDetailFromApi(
  Map<String, dynamic> json, {
  required String coinId,
  required SymbolMapper symbolMapper,
  required DateTime fetchedAt,
  String vsCurrency = 'eur',
}) {
  final marketData = json['market_data'] as Map<String, dynamic>? ?? {};
  final description = json['description'] as Map<String, dynamic>? ?? {};
  final image = json['image'] as Map<String, dynamic>? ?? {};

  final links = json['links'] as Map<String, dynamic>? ?? {};
  final homepageList = links['homepage'] as List<dynamic>? ?? [];
  final homepageUrl = homepageList
      .whereType<String>()
      .map((url) => url.trim())
      .firstWhere((url) => url.isNotEmpty, orElse: () => '');

  double? readQuoteOptional(String key) {
    final value = marketData[key];
    if (value is Map && value[vsCurrency] != null) {
      return (value[vsCurrency] as num).toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  final currentPriceEur = readQuoteOptional('current_price');
  if (currentPriceEur == null) {
    throw const FormatException('Missing current_price in market_data');
  }

  final rawDescription = description['en'] as String? ?? '';
  return CoinDetail(
    id: json['id'] as String? ?? coinId,
    symbol: (json['symbol'] as String? ?? '').toUpperCase(),
    name: json['name'] as String? ?? coinId,
    imageUrl: image['large'] as String? ?? image['small'] as String? ?? '',
    currentPriceEur: currentPriceEur,
    priceChangePercent24h:
        (marketData['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
    marketCapEur: readQuoteOptional('market_cap'),
    volume24hEur: readQuoteOptional('total_volume'),
    high24hEur: readQuoteOptional('high_24h'),
    low24hEur: readQuoteOptional('low_24h'),
    circulatingSupply: (marketData['circulating_supply'] as num?)?.toDouble(),
    athEur: readQuoteOptional('ath'),
    aboutTextEn: stripHtmlDescription(rawDescription),
    homepageUrl: homepageUrl.isEmpty ? null : homepageUrl,
    fetchedAt: fetchedAt,
    binanceSymbol: symbolMapper.binanceUsdtSymbolFor(
      coinGeckoId: coinId,
      coinGeckoSymbol: json['symbol'] as String?,
    ),
  );
}
