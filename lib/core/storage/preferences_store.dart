import 'dart:convert';

import 'package:hive/hive.dart';

/// Persists user settings JSON in the settings Hive box.
class PreferencesStore {
  /// Creates a store backed by [settingsBox].
  PreferencesStore({required Box<String> settingsBox}) : _box = settingsBox;

  static const String settingsKey = 'settings:prefs';

  final Box<String> _box;

  /// Reads raw JSON map or null when missing / corrupt.
  Future<Map<String, dynamic>?> readJson() async {
    final raw = _box.get(settingsKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _box.delete(settingsKey);
        return null;
      }
      return decoded;
    } on Object {
      await _box.delete(settingsKey);
      return null;
    }
  }

  /// Writes [value] atomically.
  Future<void> writeJson(Map<String, dynamic> value) async {
    await _box.put(settingsKey, json.encode(value));
  }

  /// Removes settings (tests / reset).
  Future<void> clear() async {
    await _box.delete(settingsKey);
  }
}
