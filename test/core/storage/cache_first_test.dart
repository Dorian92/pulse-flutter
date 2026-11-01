import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/cache_first.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';

import '../time/fake_clock.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late Directory tempDir;
  late FakeClock clock;
  late CacheStore store;
  late MockConnectivityService connectivity;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_cache_first');
    clock = FakeClock(DateTime.utc(2026, 6, 1, 12));
    connectivity = MockConnectivityService();
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

  test('returns fresh cache without calling remote', () async {
    await store.writeJson(
      key: 'markets:usd',
      payload: {'value': 'cached'},
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    var remoteCalls = 0;
    final result = await fetchCacheFirst<String>(
      cache: store,
      connectivity: connectivity,
      cacheKey: 'markets:usd',
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
      fetchRemote: () async {
        remoteCalls++;
        return const Success('remote');
      },
      decode: (json) => json['value'] as String,
      encode: (value) => {'value': value},
    );

    expect(result, isA<Success<String>>());
    expect((result as Success<String>).value, 'cached');
    expect(remoteCalls, 0);
  });

  test('offline serves stale cache with isStale', () async {
    await store.writeJson(
      key: 'markets:usd',
      payload: {'value': 'stale'},
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
    );
    clock.advance(const Duration(minutes: 20));
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await fetchCacheFirst<String>(
      cache: store,
      connectivity: connectivity,
      cacheKey: 'markets:usd',
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
      fetchRemote: () async => const Success('remote'),
      decode: (json) => json['value'] as String,
      encode: (value) => {'value': value},
    );

    expect(result, isA<Success<String>>());
    final success = result as Success<String>;
    expect(success.value, 'stale');
    expect(success.isStale, isTrue);
  });

  test('remote failure with stale cache returns Success isStale', () async {
    await store.writeJson(
      key: 'markets:usd',
      payload: {'value': 'old'},
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
    );
    clock.advance(const Duration(minutes: 20));
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    final result = await fetchCacheFirst<String>(
      cache: store,
      connectivity: connectivity,
      cacheKey: 'markets:usd',
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
      fetchRemote: () async => const Failure(ServerFailure(statusCode: 503)),
      decode: (json) => json['value'] as String,
      encode: (value) => {'value': value},
    );

    expect((result as Success<String>).isStale, isTrue);
    expect(result.value, 'old');
  });

  test('remote failure without cache returns Failure', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);

    final result = await fetchCacheFirst<String>(
      cache: store,
      connectivity: connectivity,
      cacheKey: 'missing',
      ttl: const Duration(minutes: 10),
      schemaVersion: 1,
      fetchRemote: () async => const Failure(NotFoundFailure()),
      decode: (json) => json['value'] as String,
      encode: (value) => {'value': value},
    );

    expect(result, isA<Failure<String>>());
  });
}
