import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive/hive.dart';
import 'package:pulse/core/time/clock.dart';

/// TTL cache envelope persisted as JSON in Hive.
class CacheEnvelope {
  /// Creates an envelope.
  const CacheEnvelope({
    required this.schemaVersion,
    required this.fetchedAt,
    required this.ttl,
    required this.payload,
  });

  /// Creates from JSON map.
  factory CacheEnvelope.fromJson(Map<String, dynamic> json) {
    return CacheEnvelope(
      schemaVersion: json['schemaVersion'] as int,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      ttl: Duration(seconds: json['ttlSeconds'] as int),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  /// Schema version for migrations / invalidation.
  final int schemaVersion;

  /// When the payload was stored (UTC ISO-8601 in JSON).
  final DateTime fetchedAt;

  /// Time-to-live from [fetchedAt].
  final Duration ttl;

  /// JSON-serializable payload.
  final Map<String, dynamic> payload;

  /// Whether [atUtc] is before expiry ([fetchedAt] and [atUtc] compared in UTC).
  bool isFreshAt(DateTime atUtc) {
    final expiry = fetchedAt.toUtc().add(ttl);
    return atUtc.isBefore(expiry);
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'ttlSeconds': ttl.inSeconds,
      'payload': payload,
    };
  }
}

/// Generic TTL key/value store on Hive.
class CacheStore {
  /// Creates a store backed by [cacheBox].
  CacheStore({
    required Box<String> cacheBox,
    required Clock clock,
    void Function(String message)? log,
  }) : _box = cacheBox,
       _clock = clock,
       _log = log ?? _defaultLog;

  final Box<String> _box;
  final Clock _clock;
  final void Function(String message) _log;

  /// Persists [payload] under [key] with [ttl].
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> payload,
    required Duration ttl,
    required int schemaVersion,
  }) async {
    final envelope = CacheEnvelope(
      schemaVersion: schemaVersion,
      fetchedAt: _clock.now().toUtc(),
      ttl: ttl,
      payload: payload,
    );
    await _box.put(key, json.encode(envelope.toJson()));
  }

  /// Returns payload when entry exists and TTL not expired.
  Future<Map<String, dynamic>?> readFresh({
    required String key,
    required int schemaVersion,
  }) async {
    final envelope = await _readEnvelope(key, schemaVersion);
    if (envelope == null) {
      return null;
    }
    if (envelope.isFreshAt(_clock.now().toUtc())) {
      return envelope.payload;
    }
    return null;
  }

  /// Returns payload when entry exists but TTL expired (stale).
  Future<Map<String, dynamic>?> readStale({
    required String key,
    required int schemaVersion,
  }) async {
    final envelope = await _readEnvelope(key, schemaVersion);
    if (envelope == null) {
      return null;
    }
    if (!envelope.isFreshAt(_clock.now().toUtc())) {
      return envelope.payload;
    }
    return null;
  }

  /// Deletes a cache entry.
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Clears all entries in the cache box.
  Future<void> clear() async {
    await _box.clear();
  }

  Future<CacheEnvelope?> _readEnvelope(String key, int schemaVersion) async {
    final raw = _box.get(key);
    if (raw == null) {
      return null;
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final envelope = CacheEnvelope.fromJson(map);
      if (envelope.schemaVersion != schemaVersion) {
        await _box.delete(key);
        _log(
          'Dropped cache key $key (schemaVersion ${envelope.schemaVersion} != $schemaVersion)',
        );
        return null;
      }
      return envelope;
    } on Object catch (error) {
      await _box.delete(key);
      _log('Dropped corrupt cache key $key: $error');
      return null;
    }
  }

  static void _defaultLog(String message) {
    developer.log(message, name: 'CacheStore');
  }
}
