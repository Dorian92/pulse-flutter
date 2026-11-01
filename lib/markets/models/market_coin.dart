import 'package:equatable/equatable.dart';

/// A coin row in the markets list (EUR-denominated static fields from CoinGecko).
class MarketCoin extends Equatable {
  /// Creates a market coin row.
  const MarketCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPriceEur,
    required this.priceChangePercent24h,
    required this.marketCapRank,
    required this.sparkline7d,
    this.binanceSymbol,
  });

  /// Parses from JSON map (cache or API-derived).
  factory MarketCoin.fromJson(Map<String, dynamic> json) {
    final sparklineRaw = json['sparkline7d'];
    final sparkline = sparklineRaw is List
        ? sparklineRaw.map((e) => (e as num).toDouble()).toList(growable: false)
        : const <double>[];

    return MarketCoin(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      currentPriceEur: (json['currentPriceEur'] as num?)?.toDouble() ?? 0,
      priceChangePercent24h:
          (json['priceChangePercent24h'] as num?)?.toDouble() ?? 0,
      marketCapRank: json['marketCapRank'] as int? ?? 0,
      sparkline7d: sparkline,
      binanceSymbol: json['binanceSymbol'] as String?,
    );
  }

  /// CoinGecko id (e.g. `bitcoin`).
  final String id;

  /// Ticker symbol (e.g. `btc`).
  final String symbol;

  /// Display name.
  final String name;

  /// Logo URL from CoinGecko.
  final String imageUrl;

  /// Latest price in EUR from CoinGecko REST.
  final double currentPriceEur;

  /// 24h change percentage.
  final double priceChangePercent24h;

  /// Market cap rank (1-based).
  final int marketCapRank;

  /// Seven-day sparkline prices (CoinGecko `sparkline_in_7d.price`).
  final List<double> sparkline7d;

  /// Binance USDT pair when [SymbolMapper] knows one; null → no live feed badge.
  final String? binanceSymbol;

  /// Whether a Binance live stream is expected in step 5+.
  bool get hasLiveFeed => binanceSymbol != null;

  /// Serializes for Hive cache payload.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'imageUrl': imageUrl,
      'currentPriceEur': currentPriceEur,
      'priceChangePercent24h': priceChangePercent24h,
      'marketCapRank': marketCapRank,
      'sparkline7d': sparkline7d,
      'binanceSymbol': binanceSymbol,
    };
  }

  @override
  List<Object?> get props => [
    id,
    symbol,
    name,
    imageUrl,
    currentPriceEur,
    priceChangePercent24h,
    marketCapRank,
    sparkline7d,
    binanceSymbol,
  ];
}
