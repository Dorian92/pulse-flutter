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
    required this.aboutTextEn,
    required this.fetchedAt,
    this.marketCapEur,
    this.volume24hEur,
    this.high24hEur,
    this.low24hEur,
    this.circulatingSupply,
    this.athEur,
    this.homepageUrl,
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

  /// Market cap in EUR when reported by CoinGecko.
  final double? marketCapEur;

  /// 24h volume in EUR when reported.
  final double? volume24hEur;

  /// 24h high in EUR when reported.
  final double? high24hEur;

  /// 24h low in EUR when reported.
  final double? low24hEur;

  /// Circulating supply (coin units) when reported.
  final double? circulatingSupply;

  /// All-time high in EUR when reported.
  final double? athEur;

  /// Plain-text About copy (English).
  final String aboutTextEn;

  /// Primary homepage URL from CoinGecko links, if any.
  final String? homepageUrl;

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
      homepageUrl: homepageUrl,
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
    'homepageUrl': homepageUrl,
    'fetchedAt': fetchedAt.toIso8601String(),
    'binanceSymbol': binanceSymbol,
  };

  factory CoinDetail.fromJson(Map<String, dynamic> json) {
    double? readOptional(String key) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      return (value as num).toDouble();
    }

    return CoinDetail(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      currentPriceEur: (json['currentPriceEur'] as num).toDouble(),
      priceChangePercent24h: (json['priceChangePercent24h'] as num).toDouble(),
      marketCapEur: readOptional('marketCapEur'),
      volume24hEur: readOptional('volume24hEur'),
      high24hEur: readOptional('high24hEur'),
      low24hEur: readOptional('low24hEur'),
      circulatingSupply: readOptional('circulatingSupply'),
      athEur: readOptional('athEur'),
      aboutTextEn: json['aboutTextEn'] as String,
      homepageUrl: json['homepageUrl'] as String?,
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
    homepageUrl,
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
