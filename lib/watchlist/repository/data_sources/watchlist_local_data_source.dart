import 'dart:convert';

import 'package:hive/hive.dart';

/// Hive-backed ordered watchlist coin ids.
class WatchlistLocalDataSource {
  /// Creates a local data source.
  WatchlistLocalDataSource({required Box<String> persistBox})
    : _box = persistBox;

  static const String watchlistKey = 'watchlist:entries';
  static const int schemaVersion = 1;

  final Box<String> _box;

  /// Reads ordered coin ids or empty when missing.
  Future<List<String>> readOrderedIds() async {
    final raw = _box.get(watchlistKey);
    if (raw == null) {
      return [];
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      if ((map['schemaVersion'] as int?) != schemaVersion) {
        await _box.delete(watchlistKey);
        return [];
      }
      final ids = map['coinIds'];
      if (ids is! List) {
        await _box.delete(watchlistKey);
        return [];
      }
      return ids.map((e) => e as String).toList(growable: false);
    } on Object {
      await _box.delete(watchlistKey);
      return [];
    }
  }

  /// Persists [coinIds] in display order.
  Future<void> writeOrderedIds(List<String> coinIds) async {
    final payload = json.encode({
      'schemaVersion': schemaVersion,
      'coinIds': coinIds,
    });
    await _box.put(watchlistKey, payload);
  }
}
