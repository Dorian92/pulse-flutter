import 'package:hive_flutter/hive_flutter.dart';

/// Hive box names and startup registration.
abstract final class HiveBoxes {
  /// TTL cache box name.
  static const String pulseCache = 'pulse_cache';

  /// Watchlist and other durable user data.
  static const String pulsePersist = 'pulse_persist';

  /// Theme, locale, and display currency.
  static const String pulseSettings = 'pulse_settings';

  /// Initializes Hive (Flutter or tests) and opens required boxes.
  static Future<void> init({String? path}) async {
    if (Hive.isBoxOpen(pulseCache) &&
        Hive.isBoxOpen(pulsePersist) &&
        Hive.isBoxOpen(pulseSettings)) {
      return;
    }
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    await openBoxes();
  }

  /// Opens boxes when [Hive.init] was already called (tests).
  static Future<void> openBoxes() async {
    if (!Hive.isBoxOpen(pulseCache)) {
      await Hive.openBox<String>(pulseCache);
    }
    if (!Hive.isBoxOpen(pulsePersist)) {
      await Hive.openBox<String>(pulsePersist);
    }
    if (!Hive.isBoxOpen(pulseSettings)) {
      await Hive.openBox<String>(pulseSettings);
    }
  }
}
