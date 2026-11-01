import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/price_tick.dart';
import 'package:pulse/core/realtime/realtime_status.dart';

/// Manual [PriceStreamService] for bloc and widget tests.
class FakePriceStreamService implements PriceStreamService {
  final StreamController<PriceTick> _ticksController =
      StreamController<PriceTick>.broadcast();
  final StreamController<RealtimeStatus> _statusController =
      StreamController<RealtimeStatus>.broadcast();

  Set<String> lastDesiredSymbols = {};
  AppLifecycleState? lastLifecycle;

  RealtimeStatus _currentStatus = const RealtimeStatus.offline();

  FakePriceStreamService() {
    // Status starts offline until tests call [emitStatus].
  }

  @override
  RealtimeStatus get currentStatus => _currentStatus;

  @override
  Stream<PriceTick> get ticks => _ticksController.stream;

  @override
  Stream<RealtimeStatus> get status => _statusController.stream;

  @override
  void setDesiredSymbols(Set<String> lowercaseBinanceSymbols) {
    lastDesiredSymbols = Set<String>.from(lowercaseBinanceSymbols);
  }

  @override
  void setAppLifecycle(AppLifecycleState state) {
    lastLifecycle = state;
  }

  /// Pushes a tick to listeners.
  void emitTick(PriceTick tick) {
    _ticksController.add(tick);
  }

  /// Pushes a status update.
  void emitStatus(RealtimeStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Simulates a disconnect.
  void simulateDisconnect() {
    emitStatus(const RealtimeStatus.reconnecting());
  }

  /// Simulates reconnect success.
  void simulateReconnect() {
    emitStatus(const RealtimeStatus.live());
  }

  @override
  Future<void> dispose() async {
    await _ticksController.close();
    await _statusController.close();
  }
}
