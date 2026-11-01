import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/realtime/symbol_mapper_loader.dart';
import 'package:pulse/core/storage/cache_store.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockCacheStore extends Mock implements CacheStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(days: 7));
    registerFallbackValue(<String, dynamic>{});
  });

  late MockApiClient apiClient;
  late MockCacheStore cacheStore;
  late SymbolMapper mapper;

  setUp(() {
    apiClient = MockApiClient();
    cacheStore = MockCacheStore();
    mapper = SymbolMapper();
  });

  test('warmUp applies fresh cache without remote call', () async {
    when(
      () => cacheStore.readFresh(
        key: any(named: 'key'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer(
      (_) async => {
        'bases': {'SOL': 'SOLUSDT'},
      },
    );

    final loader = SymbolMapperLoader(
      apiClient: apiClient,
      cacheStore: cacheStore,
      symbolMapper: mapper,
    );

    final result = await loader.warmUp();

    expect(result, isA<Success<bool>>());
    expect(
      mapper.binanceUsdtSymbolFor(coinGeckoId: 'x', coinGeckoSymbol: 'sol'),
      'SOLUSDT',
    );
    verifyNever(
      () => apiClient.getBinanceJson<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    );
  });

  test('warmUp parses remote exchangeInfo and writes cache', () async {
    when(
      () => cacheStore.readFresh(
        key: any(named: 'key'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => apiClient.getBinanceJson<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as Map<String, dynamic> Function(Object?);
      final parsed = decode({
        'symbols': [
          {
            'status': 'TRADING',
            'quoteAsset': 'USDT',
            'baseAsset': 'ADA',
            'symbol': 'ADAUSDT',
          },
        ],
      });
      return Success(parsed);
    });

    when(
      () => cacheStore.writeJson(
        key: any(named: 'key'),
        payload: any(named: 'payload'),
        ttl: any(named: 'ttl'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async {});

    final loader = SymbolMapperLoader(
      apiClient: apiClient,
      cacheStore: cacheStore,
      symbolMapper: mapper,
    );

    final result = await loader.warmUp();

    expect(result, isA<Success<bool>>());
    expect(
      mapper.binanceUsdtSymbolFor(
        coinGeckoId: 'cardano',
        coinGeckoSymbol: 'ada',
      ),
      'ADAUSDT',
    );
    verify(
      () => cacheStore.writeJson(
        key: any(named: 'key'),
        payload: any(named: 'payload'),
        ttl: any(named: 'ttl'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).called(1);
  });

  test('warmUp skips corrupt fresh cache and uses remote', () async {
    when(
      () => cacheStore.readFresh(
        key: any(named: 'key'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async => {'unexpected': true});

    when(
      () => apiClient.getBinanceJson<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as Map<String, dynamic> Function(Object?);
      final parsed = decode({
        'symbols': [
          {
            'status': 'TRADING',
            'quoteAsset': 'USDT',
            'baseAsset': 'DOT',
            'symbol': 'DOTUSDT',
          },
        ],
      });
      return Success(parsed);
    });

    when(
      () => cacheStore.writeJson(
        key: any(named: 'key'),
        payload: any(named: 'payload'),
        ttl: any(named: 'ttl'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async {});

    final loader = SymbolMapperLoader(
      apiClient: apiClient,
      cacheStore: cacheStore,
      symbolMapper: mapper,
    );

    final result = await loader.warmUp();

    expect(result, isA<Success<bool>>());
    expect(
      mapper.binanceUsdtSymbolFor(
        coinGeckoId: 'polkadot',
        coinGeckoSymbol: 'dot',
      ),
      'DOTUSDT',
    );
  });

  test('warmUp falls back to stale cache when remote fails', () async {
    when(
      () => cacheStore.readFresh(
        key: any(named: 'key'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => apiClient.getBinanceJson<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkFailure(offline: true)));

    when(
      () => cacheStore.readStale(
        key: any(named: 'key'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer(
      (_) async => {
        'bases': {'XRP': 'XRPUSDT'},
      },
    );

    final loader = SymbolMapperLoader(
      apiClient: apiClient,
      cacheStore: cacheStore,
      symbolMapper: mapper,
    );

    final result = await loader.warmUp();

    expect(result, isA<Success<bool>>());
    final success = result as Success<bool>;
    expect(success.isStale, isTrue);
    expect(
      mapper.binanceUsdtSymbolFor(
        coinGeckoId: 'ripple',
        coinGeckoSymbol: 'xrp',
      ),
      'XRPUSDT',
    );
  });
}
