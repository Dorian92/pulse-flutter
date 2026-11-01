import 'package:pulse/core/time/clock.dart';

/// Mutable clock for unit tests.
class FakeClock implements Clock {
  FakeClock([DateTime? initial]) : _now = initial ?? DateTime.utc(2026);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Advances the fake clock.
  void advance(Duration delta) {
    _now = _now.add(delta);
  }

  /// Sets absolute time.
  set nowValue(DateTime value) => _now = value;
}
