import 'package:flutter/widgets.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';

/// Shared Binance WebSocket price pipeline (see [docs/realtime.md](https://github.com/Dorian92/pulse-flutter/blob/main/docs/realtime.md)).
abstract class PriceStreamService {
  /// Throttled EUR price updates for subscribed symbols.
  Stream<PriceTick> get ticks;

  /// Connection lifecycle for UI indicators.
  Stream<RealtimeStatus> get status;

  /// Latest status (for UI seeding before the next stream event).
  RealtimeStatus get currentStatus;

  /// Replaces the desired subscription set (lowercase Binance symbols, e.g. `btcusdt`).
  ///
  /// The service always subscribes to `eurusdt` internally for EUR conversion.
  void setDesiredSymbols(Set<String> lowercaseBinanceSymbols);

  /// Applies foreground/background policy (disconnect after delay when paused).
  void setAppLifecycle(AppLifecycleState state);

  /// Closes sockets and timers.
  Future<void> dispose();
}
