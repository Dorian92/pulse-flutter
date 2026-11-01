import 'package:equatable/equatable.dart';

/// Connection health for live Binance streams.
sealed class RealtimeStatus extends Equatable {
  const RealtimeStatus();

  /// No active socket (idle, background teardown, or no subscriptions).
  const factory RealtimeStatus.offline() = RealtimeOffline;

  /// Opening a WebSocket or waiting for first message.
  const factory RealtimeStatus.connecting() = RealtimeConnecting;

  /// Receiving ticks on subscribed streams.
  const factory RealtimeStatus.live() = RealtimeLive;

  /// Backoff before reconnect after an error or 24h disconnect.
  const factory RealtimeStatus.reconnecting() = RealtimeReconnecting;

  /// Subscribed but no fresh data within the stale window.
  const factory RealtimeStatus.degraded() = RealtimeDegraded;

  /// True when the LIVE header indicator should appear active.
  bool get isLiveIndicatorActive => this is RealtimeLive;

  @override
  List<Object?> get props => [runtimeType];
}

/// See [RealtimeStatus.offline].
final class RealtimeOffline extends RealtimeStatus {
  /// Creates offline status.
  const RealtimeOffline();
}

/// See [RealtimeStatus.connecting].
final class RealtimeConnecting extends RealtimeStatus {
  /// Creates connecting status.
  const RealtimeConnecting();
}

/// See [RealtimeStatus.live].
final class RealtimeLive extends RealtimeStatus {
  /// Creates live status.
  const RealtimeLive();
}

/// See [RealtimeStatus.reconnecting].
final class RealtimeReconnecting extends RealtimeStatus {
  /// Creates reconnecting status.
  const RealtimeReconnecting();
}

/// See [RealtimeStatus.degraded].
final class RealtimeDegraded extends RealtimeStatus {
  /// Creates degraded status.
  const RealtimeDegraded();
}
