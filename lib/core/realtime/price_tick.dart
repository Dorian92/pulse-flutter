import 'package:equatable/equatable.dart';

/// A throttled live price update for one Binance USDT pair.
class PriceTick extends Equatable {
  /// Creates a tick.
  const PriceTick({
    required this.symbol,
    required this.lastPriceUsdt,
    required this.lastPriceEur,
    required this.eventTime,
    this.changePercent24h,
  });

  /// Binance symbol in uppercase (e.g. `BTCUSDT`).
  final String symbol;

  /// Last price in USDT from the Binance ticker (`c` field).
  final double lastPriceUsdt;

  /// Last price converted to EUR for display (step 7 may convert USDT for USD).
  final double lastPriceEur;

  /// 24h change percentage from the ticker `P` field when present.
  final double? changePercent24h;

  /// Event time from the exchange (`E` field).
  final DateTime eventTime;

  @override
  List<Object?> get props => [
    symbol,
    lastPriceUsdt,
    lastPriceEur,
    changePercent24h,
    eventTime,
  ];
}
