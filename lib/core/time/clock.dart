/// Provides the current time (injectable for tests).
abstract class Clock {
  /// Current UTC or local time depending on implementation.
  DateTime now();
}

/// Uses the system clock.
class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
