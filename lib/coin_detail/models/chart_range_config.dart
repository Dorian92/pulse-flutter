import 'package:pulse/core/widgets/period_selector.dart';

/// Cache segment, TTL, and remote parameters for each [ChartPeriod].
extension ChartRangeConfig on ChartPeriod {
  /// Key segment in `chart:{id}:{segment}:eur`.
  String get cacheSegment {
    return switch (this) {
      ChartPeriod.oneDay => '1d',
      ChartPeriod.oneWeek => '1w',
      ChartPeriod.oneMonth => '1m',
      ChartPeriod.threeMonths => '3m',
      ChartPeriod.oneYear => '1y',
    };
  }

  /// TTL from [docs/caching.md](https://github.com/Dorian92/pulse-flutter/blob/main/docs/caching.md).
  Duration get chartTtl {
    return switch (this) {
      ChartPeriod.oneDay => const Duration(minutes: 5),
      ChartPeriod.oneWeek => const Duration(minutes: 15),
      ChartPeriod.oneMonth => const Duration(hours: 1),
      ChartPeriod.threeMonths => const Duration(hours: 6),
      ChartPeriod.oneYear => const Duration(hours: 24),
    };
  }

  /// CoinGecko `days` query parameter.
  int get coinGeckoDays {
    return switch (this) {
      ChartPeriod.oneDay => 1,
      ChartPeriod.oneWeek => 7,
      ChartPeriod.oneMonth => 30,
      ChartPeriod.threeMonths => 90,
      ChartPeriod.oneYear => 365,
    };
  }

  /// Binance kline interval and candle limit when a USDT pair exists.
  (String interval, int limit) get binanceKlineParams {
    return switch (this) {
      ChartPeriod.oneDay => ('5m', 288),
      ChartPeriod.oneWeek => ('1h', 168),
      ChartPeriod.oneMonth => ('4h', 180),
      ChartPeriod.threeMonths => ('1d', 90),
      ChartPeriod.oneYear => ('1d', 365),
    };
  }
}
