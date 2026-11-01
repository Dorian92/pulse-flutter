import 'package:equatable/equatable.dart';

/// CoinGecko metadata and market stats for the detail screen.
class CoinDetail extends Equatable {
  /// Creates detail data.
  const CoinDetail({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPriceEur,
    required this.priceChangePercent24h,
    required this.marketCapEur,
    required this.volume24hEur,
    required this.high24hEur,
    required this.low24hEur,
    required this.circulatingSupply,
    required this.athEur,
    required this.aboutTextEn,
    required this.fetchedAt,
    this.binanceSymbol,
  });

  /// CoinGecko id.
  final String id;

  /// Ticker (uppercase in UI).
  final String symbol;

  /// Display name.
  final String name;

  /// Logo URL.
  final String imageUrl;

  /// Last price in EUR from CoinGecko market_data.
  final double currentPriceEur;

  /// 24h change percentage.
  final double priceChangePercent24h;

  /// Market cap in EUR.
  final double marketCapEur;

  /// 24h volume in EUR.
  final double volume24hEur;

  /// 24h high in EUR.
  final double high24hEur;

  /// 24h low in EUR.
  final double low24hEur;

  /// Circulating supply (coin units).
  final double circulatingSupply;

  /// All-time high in EUR.
  final double athEur;

  /// Plain-text About copy (English).
  final String aboutTextEn;

  /// When metadata was fetched (UTC).
  final DateTime fetchedAt;

  /// Binance USDT pair when known.
  final String? binanceSymbol;

  /// Whether live Binance stream is expected.
  bool get hasLiveFeed => binanceSymbol != null;

  CoinDetail copyWith({
    double? currentPriceEur,
    double? priceChangePercent24h,
  }) {
    return CoinDetail(
      id: id,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
      currentPriceEur: currentPriceEur ?? this.currentPriceEur,
      priceChangePercent24h:
          priceChangePercent24h ?? this.priceChangePercent24h,
      marketCapEur: marketCapEur,
      volume24hEur: volume24hEur,
      high24hEur: high24hEur,
      low24hEur: low24hEur,
      circulatingSupply: circulatingSupply,
      athEur: athEur,
      aboutTextEn: aboutTextEn,
      fetchedAt: fetchedAt,
      binanceSymbol: binanceSymbol,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'imageUrl': imageUrl,
    'currentPriceEur': currentPriceEur,
    'priceChangePercent24h': priceChangePercent24h,
    'marketCapEur': marketCapEur,
    'volume24hEur': volume24hEur,
    'high24hEur': high24hEur,
    'low24hEur': low24hEur,
    'circulatingSupply': circulatingSupply,
    'athEur': athEur,
    'aboutTextEn': aboutTextEn,
    'fetchedAt': fetchedAt.toIso8601String(),
    'binanceSymbol': binanceSymbol,
  };

  factory CoinDetail.fromJson(Map<String, dynamic> json) {
    return CoinDetail(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      currentPriceEur: (json['currentPriceEur'] as num).toDouble(),
      priceChangePercent24h: (json['priceChangePercent24h'] as num).toDouble(),
      marketCapEur: (json['marketCapEur'] as num).toDouble(),
      volume24hEur: (json['volume24hEur'] as num).toDouble(),
      high24hEur: (json['high24hEur'] as num).toDouble(),
      low24hEur: (json['low24hEur'] as num).toDouble(),
      circulatingSupply: (json['circulatingSupply'] as num).toDouble(),
      athEur: (json['athEur'] as num).toDouble(),
      aboutTextEn: json['aboutTextEn'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
      binanceSymbol: json['binanceSymbol'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    symbol,
    name,
    imageUrl,
    currentPriceEur,
    priceChangePercent24h,
    marketCapEur,
    volume24hEur,
    high24hEur,
    low24hEur,
    circulatingSupply,
    athEur,
    aboutTextEn,
    fetchedAt,
    binanceSymbol,
  ];
}

/// Strips HTML tags from CoinGecko descriptions.
String stripHtmlDescription(String html) {
  return html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
