import 'package:hive_flutter/hive_flutter.dart';

/// Hive box names and startup registration.
abstract final class HiveBoxes {
  /// TTL cache box name.
  static const String pulseCache = 'pulse_cache';

  /// Initializes Hive (Flutter or tests) and opens required boxes.
  static Future<void> init({String? path}) async {
    if (Hive.isBoxOpen(pulseCache)) {
      return;
    }
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    await Hive.openBox<String>(pulseCache);
  }

  /// Opens boxes when [Hive.init] was already called (tests).
  static Future<void> openBoxes() async {
    if (!Hive.isBoxOpen(pulseCache)) {
      await Hive.openBox<String>(pulseCache);
    }
  }
}
