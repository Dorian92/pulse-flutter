import 'dart:async';

import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/preferences_store.dart';
import 'package:pulse/settings/models/user_preferences.dart';

/// Loads and persists [UserPreferences]; notifies listeners on change.
class SettingsRepository {
  /// Creates the repository.
  SettingsRepository({
    required PreferencesStore preferencesStore,
    required CacheStore cacheStore,
  }) : _preferencesStore = preferencesStore,
       _cacheStore = cacheStore;

  static const int schemaVersion = 1;

  final PreferencesStore _preferencesStore;
  final CacheStore _cacheStore;

  UserPreferences _current = UserPreferences.defaults;
  final StreamController<UserPreferences> _changes =
      StreamController<UserPreferences>.broadcast();

  /// Latest preferences (after [load] or [save]).
  UserPreferences get current => _current;

  /// Emits whenever [save] updates preferences.
  Stream<UserPreferences> get changes => _changes.stream;

  /// Reads Hive or keeps defaults when missing.
  Future<UserPreferences> load() async {
    final json = await _preferencesStore.readJson();
    if (json == null) {
      _current = UserPreferences.defaults;
      return _current;
    }
    if ((json['schemaVersion'] as int?) != schemaVersion) {
      await _preferencesStore.clear();
      _current = UserPreferences.defaults;
      return _current;
    }
    _current = UserPreferences.fromJson(json);
    return _current;
  }

  /// Persists and broadcasts [preferences].
  Future<void> save(UserPreferences preferences) async {
    _current = preferences;
    await _preferencesStore.writeJson(preferences.toJson());
    _changes.add(_current);
  }

  /// Clears TTL cache entries only (watchlist/settings untouched).
  Future<void> clearCache() => _cacheStore.clear();

  /// Releases stream resources (tests).
  Future<void> dispose() async {
    await _changes.close();
  }
}
