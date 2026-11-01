import 'package:equatable/equatable.dart';

/// A throttled live price update for one Binance USDT pair (EUR-converted).
class PriceTick extends Equatable {
  /// Creates a tick.
  const PriceTick({
    required this.symbol,
    required this.lastPriceEur,
    required this.eventTime,
    this.changePercent24h,
  });

  /// Binance symbol in uppercase (e.g. `BTCUSDT`).
  final String symbol;

  /// Last price converted to EUR for display.
  final double lastPriceEur;

  /// 24h change percentage from the ticker `P` field when present.
  final double? changePercent24h;

  /// Event time from the exchange (`E` field).
  final DateTime eventTime;

  @override
  List<Object?> get props => [
    symbol,
    lastPriceEur,
    changePercent24h,
    eventTime,
  ];
}
