import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import '../time/fake_clock.dart';

void main() {
  late Directory tempDir;
  late FakeClock clock;
  late CacheStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_cache_test');
    clock = FakeClock(DateTime.utc(2026, 6, 1, 12));
    await HiveBoxes.init(path: tempDir.path);
    store = CacheStore(
      cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
      clock: clock,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('readFresh returns payload within TTL', () async {
    await store.writeJson(
      key: 'markets:usd',
      payload: {'count': 1},
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
    );
    final fresh = await store.readFresh(key: 'markets:usd', schemaVersion: 1);
    expect(fresh, {'count': 1});
  });

  test('readStale after TTL expires', () async {
    await store.writeJson(
      key: 'markets:usd',
      payload: {'count': 2},
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
    );
    clock.advance(const Duration(minutes: 11));
    expect(await store.readFresh(key: 'markets:usd', schemaVersion: 1), isNull);
    expect(await store.readStale(key: 'markets:usd', schemaVersion: 1), {
      'count': 2,
    });
  });

  test('drops corrupt entries', () async {
    final box = Hive.box<String>(HiveBoxes.pulseCache);
    await box.put('bad', 'not-json');
    expect(await store.readFresh(key: 'bad', schemaVersion: 1), isNull);
    expect(box.get('bad'), isNull);
  });

  test('drops schema version mismatch', () async {
    await store.writeJson(
      key: 'coin:bitcoin',
      payload: {'id': 'bitcoin'},
      ttl: const Duration(hours: 1),
      schemaVersion: 1,
    );
    expect(
      await store.readFresh(key: 'coin:bitcoin', schemaVersion: 2),
      isNull,
    );
  });

  test('clear removes all keys', () async {
    await store.writeJson(
      key: 'a',
      payload: {'a': 1},
      ttl: const Duration(minutes: 1),
      schemaVersion: 1,
    );
    await store.clear();
    expect(await store.readStale(key: 'a', schemaVersion: 1), isNull);
  });
}
