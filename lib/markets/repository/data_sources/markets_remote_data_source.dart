import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/time/clock.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';

/// Fetches markets list and global summary from CoinGecko.
class MarketsRemoteDataSource {
  /// Creates a remote data source.
  MarketsRemoteDataSource({
    required ApiClient apiClient,
    required SymbolMapper symbolMapper,
    required Clock clock,
    this.vsCurrency = 'eur',
    this.perPage = 100,
  }) : _apiClient = apiClient,
       _symbolMapper = symbolMapper,
       _clock = clock;

  final ApiClient _apiClient;
  final SymbolMapper _symbolMapper;
  final Clock _clock;

  /// Quote currency for CoinGecko (EUR for this phase).
  final String vsCurrency;

  /// Number of coins per page (max 250 on CoinGecko).
  final int perPage;

  /// Loads markets snapshot from network.
  Future<Result<MarketsSnapshot>> fetchMarkets() async {
    final results = await Future.wait([_fetchMarketsPage(), _fetchGlobal()]);

    final marketsResult = results[0] as Result<List<MarketCoin>>;
    final globalResult = results[1] as Result<GlobalMarketSummary>;

    if (marketsResult case Failure(:final error)) {
      return Failure(error);
    }
    if (globalResult case Failure(:final error)) {
      return Failure(error);
    }

    final markets = (marketsResult as Success<List<MarketCoin>>).value;
    final global = (globalResult as Success<GlobalMarketSummary>).value;

    return Success(
      MarketsSnapshot(
        coins: markets,
        global: global,
        fetchedAt: _clock.now().toUtc(),
      ),
    );
  }

  Future<Result<List<MarketCoin>>> _fetchMarketsPage() async {
    return _apiClient.getCoinGeckoJson<List<MarketCoin>>(
      path: '/coins/markets',
      queryParameters: {
        'vs_currency': vsCurrency,
        'order': 'market_cap_desc',
        'per_page': '$perPage',
        'page': '1',
        'sparkline': 'true',
        'price_change_percentage': '24h',
      },
      decode: (json) {
        if (json is! List) {
          throw const FormatException('Expected list for /coins/markets');
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

  Future<Result<GlobalMarketSummary>> _fetchGlobal() async {
    return _apiClient.getCoinGeckoJson<GlobalMarketSummary>(
      path: '/global',
      decode: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Expected map for /global');
        }
        return parseGlobalMarketSummaryFromApi(json, vsCurrency: vsCurrency);
      },
    );
  }
}

/// Parses a CoinGecko `/coins/markets` row into [MarketCoin].
MarketCoin parseMarketCoinFromApi(
  Map<String, dynamic> json, {
  required SymbolMapper symbolMapper,
}) {
  final id = json['id'] as String? ?? '';
  final sparklineMap = json['sparkline_in_7d'] as Map<String, dynamic>?;
  final prices = sparklineMap?['price'] as List<dynamic>?;
  final sparkline =
      prices?.map((e) => (e as num).toDouble()).toList(growable: false) ??
      const <double>[];

  return MarketCoin(
    id: id,
    symbol: json['symbol'] as String? ?? '',
    name: json['name'] as String? ?? '',
    imageUrl: json['image'] as String? ?? '',
    currentPriceEur: (json['current_price'] as num?)?.toDouble() ?? 0,
    priceChangePercent24h:
        (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
    marketCapRank: json['market_cap_rank'] as int? ?? 0,
    sparkline7d: sparkline,
    binanceSymbol: symbolMapper.binanceUsdtSymbolFor(coinGeckoId: id),
  );
}

/// Parses CoinGecko `/global` payload into [GlobalMarketSummary].
GlobalMarketSummary parseGlobalMarketSummaryFromApi(
  Map<String, dynamic> json, {
  required String vsCurrency,
}) {
  final data = json['data'] as Map<String, dynamic>? ?? json;
  final caps = data['total_market_cap'] as Map<String, dynamic>? ?? {};
  final eurCap = (caps[vsCurrency] as num?)?.toDouble();
  final change =
      (data['market_cap_change_percentage_24h_usd'] as num?)?.toDouble() ?? 0;
  return GlobalMarketSummary(
    totalMarketCapEur: eurCap,
    marketCapChangePercent24h: change,
  );
}
