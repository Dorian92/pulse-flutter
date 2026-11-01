import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/util/stable_hash.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_markets_data_source.dart';

import '../../core/time/fake_clock.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late Directory tempDir;
  late FakeClock clock;
  late CacheStore cache;
  late MockApiClient apiClient;
  late MockSettingsRepository settings;
  late WatchlistMarketsDataSource dataSource;

  const prefs = UserPreferences(
    themeMode: ThemeMode.dark,
    localeCode: 'en',
    displayCurrency: DisplayCurrency.eur,
  );

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_wl_markets_ds');
    clock = FakeClock(DateTime.utc(2026, 6, 1, 12));
    await HiveBoxes.init(path: tempDir.path);
    cache = CacheStore(
      cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
      clock: clock,
    );
    apiClient = MockApiClient();
    settings = MockSettingsRepository();
    when(() => settings.current).thenReturn(prefs);
    dataSource = WatchlistMarketsDataSource(
      apiClient: apiClient,
      symbolMapper: SymbolMapper(),
      cacheStore: cache,
      settingsRepository: settings,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('fetchByIds returns empty without network', () async {
    final result = await dataSource.fetchByIds(const []);
    expect(result, isA<Success<List<MarketCoin>>>());
    expect((result as Success).value, isEmpty);
    verifyNever(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    );
  });

  test('fetchByIds uses fresh cache without remote call', () async {
    const ids = ['bitcoin', 'ethereum'];
    final hash = stableHashForSortedIds(ids);
    final key = 'markets:by_ids:eur:$hash';
    await cache.writeJson(
      key: key,
      payload: {
        'coins': [
          const MarketCoin(
            id: 'bitcoin',
            symbol: 'btc',
            name: 'Bitcoin',
            imageUrl: '',
            currentPriceEur: 1,
            priceChangePercent24h: 1,
            marketCapRank: 1,
            sparkline7d: [1],
          ).toJson(),
        ],
      },
      ttl: WatchlistMarketsDataSource.ttl,
      schemaVersion: WatchlistMarketsDataSource.schemaVersion,
    );

    final result = await dataSource.fetchByIds(ids);
    expect(result, isA<Success<List<MarketCoin>>>());
    expect((result as Success).value.single.id, 'bitcoin');
    verifyNever(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    );
  });

  test('fetchByIds returns stale when remote fails', () async {
    const ids = ['chainlink'];
    final fixture = File(
      'test/markets/fixtures/coingecko_markets_page1.json',
    ).readAsStringSync();
    final bitcoinJson =
        (json.decode(fixture) as List).first as Map<String, dynamic>;

    final hash = stableHashForSortedIds(ids);
    final key = 'markets:by_ids:eur:$hash';
    await cache.writeJson(
      key: key,
      payload: {
        'coins': [
          MarketCoin(
            id: 'chainlink',
            symbol: 'link',
            name: 'Chainlink',
            imageUrl: '',
            currentPriceEur: (bitcoinJson['current_price'] as num).toDouble(),
            priceChangePercent24h:
                (bitcoinJson['price_change_percentage_24h'] as num).toDouble(),
            marketCapRank: bitcoinJson['market_cap_rank'] as int,
            sparkline7d: const [1],
          ).toJson(),
        ],
      },
      ttl: WatchlistMarketsDataSource.ttl,
      schemaVersion: WatchlistMarketsDataSource.schemaVersion,
    );
    clock.advance(const Duration(minutes: 11));

    when(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkFailure(offline: true)));

    final result = await dataSource.fetchByIds(ids);
    expect(result, isA<Success<List<MarketCoin>>>());
    final success = result as Success<List<MarketCoin>>;
    expect(success.isStale, isTrue);
    expect(success.refreshError, isA<NetworkFailure>());
    expect(success.value.single.id, 'chainlink');
  });

  test('fetchByIds fetches remote on cache miss and writes cache', () async {
    const ids = ['bitcoin'];
    final fixture = File(
      'test/markets/fixtures/coingecko_markets_page1.json',
    ).readAsStringSync();

    when(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: '/coins/markets',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as List<MarketCoin> Function(Object? json);
      final list = json.decode(fixture) as List<dynamic>;
      return Success(decode(list));
    });

    final result = await dataSource.fetchByIds(ids);
    expect(result, isA<Success<List<MarketCoin>>>());
    expect((result as Success).value.first.id, 'bitcoin');

    final hash = stableHashForSortedIds(ids);
    final key = 'markets:by_ids:eur:$hash';
    final cached = await cache.readFresh(
      key: key,
      schemaVersion: WatchlistMarketsDataSource.schemaVersion,
    );
    expect(cached, isNotNull);
    verify(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: '/coins/markets',
        queryParameters: {
          'vs_currency': 'eur',
          'ids': 'bitcoin',
          'sparkline': 'true',
          'price_change_percentage': '24h',
        },
        decode: any(named: 'decode'),
      ),
    ).called(1);
  });

  test('refreshByIds bypasses TTL', () async {
    const ids = ['bitcoin'];
    final hash = stableHashForSortedIds(ids);
    final key = 'markets:by_ids:eur:$hash';
    await cache.writeJson(
      key: key,
      payload: {
        'coins': [
          const MarketCoin(
            id: 'bitcoin',
            symbol: 'btc',
            name: 'Bitcoin',
            imageUrl: '',
            currentPriceEur: 1,
            priceChangePercent24h: 1,
            marketCapRank: 1,
            sparkline7d: [1],
          ).toJson(),
        ],
      },
      ttl: WatchlistMarketsDataSource.ttl,
      schemaVersion: WatchlistMarketsDataSource.schemaVersion,
    );

    final fixture = File(
      'test/markets/fixtures/coingecko_markets_page1.json',
    ).readAsStringSync();

    when(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: '/coins/markets',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as List<MarketCoin> Function(Object? json);
      return Success(decode(json.decode(fixture)));
    });

    final result = await dataSource.refreshByIds(ids);
    expect(result, isA<Success<List<MarketCoin>>>());
    verify(
      () => apiClient.getCoinGeckoJson<List<MarketCoin>>(
        path: '/coins/markets',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).called(1);
  });
}
