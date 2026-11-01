import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/time/clock.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockClock extends Mock implements Clock {}

void main() {
  late MockHttpClient client;
  late MockClock clock;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.binance.com'));
  });

  setUp(() {
    client = MockHttpClient();
    clock = MockClock();
    when(() => clock.now()).thenReturn(DateTime.utc(2026));
    apiClient = ApiClient(
      httpClient: client,
      config: const AppConfig(
        connectTimeout: Duration(milliseconds: 50),
        receiveTimeout: Duration(milliseconds: 50),
        apiMaxAttempts: 1,
      ),
      clock: clock,
      log: (_) {},
    );
  });

  test('returns decoded JSON on 200', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(json.encode({'ok': true}), 200));

    final result = await apiClient.getBinanceJson<Map<String, dynamic>>(
      path: '/api/v3/ping',
      decode: (json) => Map<String, dynamic>.from(json! as Map),
    );

    expect(result, isA<Success<Map<String, dynamic>>>());
    expect((result as Success).value, {'ok': true});
  });

  test('maps 404 to NotFoundFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('missing', 404));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/missing',
      decode: (json) => json,
    );

    expect((result as Failure).error, isA<NotFoundFailure>());
  });

  test('maps 429 to RateLimitFailure with retry-after', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async =>
          http.Response('slow down', 429, headers: {'retry-after': '12'}),
    );

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ticker/price',
      decode: (json) => json,
      maxAttempts: 1,
    );

    final error = (result as Failure).error as RateLimitFailure;
    expect(error.retryAfterSeconds, 12);
  });

  test('does not retry 429 when Retry-After exceeds cap', () async {
    var calls = 0;
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
      _,
    ) async {
      calls++;
      return http.Response('slow down', 429, headers: {'retry-after': '120'});
    });

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ticker/price',
      decode: (json) => json,
      maxAttempts: 3,
    );

    expect(calls, 1);
    expect(
      (result as Failure).error,
      isA<RateLimitFailure>().having(
        (e) => e.retryAfterSeconds,
        'retryAfterSeconds',
        120,
      ),
    );
  });

  test('retries 429 after Retry-After then succeeds', () async {
    var calls = 0;
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
      _,
    ) async {
      calls++;
      if (calls == 1) {
        return http.Response('slow down', 429, headers: {'retry-after': '1'});
      }
      return http.Response(json.encode({'ok': true}), 200);
    });

    final retryClient = ApiClient(
      httpClient: client,
      config: const AppConfig(
        connectTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 1),
      ),
      clock: clock,
      log: (_) {},
    );

    final result = await retryClient.getBinanceJson<Map<String, dynamic>>(
      path: '/api/v3/ping',
      decode: (json) => Map<String, dynamic>.from(json! as Map),
    );

    expect(result, isA<Success<Map<String, dynamic>>>());
    expect(calls, 2);
  });

  test('maps 418 to ServerFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('banned', 418));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    expect(
      (result as Failure).error,
      isA<ServerFailure>().having((e) => e.statusCode, 'statusCode', 418),
    );
  });

  test('maps 401 and 403 to ServerFailure', () async {
    for (final code in [401, 403]) {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('auth', code));

      final result = await apiClient.getBinanceJson<Object?>(
        path: '/api/v3/ping',
        decode: (json) => json,
      );

      expect(
        (result as Failure).error,
        isA<ServerFailure>().having((e) => e.statusCode, 'statusCode', code),
      );
    }
  });

  test('maps 500 to ServerFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('error', 500));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    expect((result as Failure).error, isA<ServerFailure>());
  });

  test('invalid JSON maps to ParsingFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('not-json', 200));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    expect((result as Failure).error, isA<ParsingFailure>());
  });

  test('decode throw maps to ParsingFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(json.encode({'ok': true}), 200));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (_) => throw StateError('bad dto'),
    );

    expect((result as Failure).error, isA<ParsingFailure>());
  });

  test('retries transient 503 then succeeds', () async {
    var calls = 0;
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
      _,
    ) async {
      calls++;
      if (calls == 1) {
        return http.Response('unavailable', 503);
      }
      return http.Response(json.encode({'ok': true}), 200);
    });

    final retryClient = ApiClient(
      httpClient: client,
      config: const AppConfig(
        connectTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 1),
      ),
      clock: clock,
      log: (_) {},
    );

    final result = await retryClient.getBinanceJson<Map<String, dynamic>>(
      path: '/api/v3/ping',
      decode: (json) => Map<String, dynamic>.from(json! as Map),
    );

    expect(result, isA<Success<Map<String, dynamic>>>());
    expect(calls, 2);
  });

  test('exhausts max attempts on 502 and 504', () async {
    for (final status in [502, 504]) {
      var calls = 0;
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
        _,
      ) async {
        calls++;
        return http.Response('bad gateway', status);
      });

      final retryClient = ApiClient(
        httpClient: client,
        config: const AppConfig(
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 1),
        ),
        clock: clock,
        log: (_) {},
      );

      final result = await retryClient.getBinanceJson<Object?>(
        path: '/api/v3/ping',
        decode: (json) => json,
      );

      expect(calls, 3);
      expect(
        (result as Failure).error,
        isA<ServerFailure>().having((e) => e.statusCode, 'statusCode', status),
      );
    }
  });

  test('receive timeout maps to TimeoutFailure', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
      _,
    ) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return http.Response('{}', 200);
    });

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    expect((result as Failure).error, isA<TimeoutFailure>());
  });

  test('socket error maps to offline NetworkFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenThrow(const SocketException('failed'));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    final error = (result as Failure).error as NetworkFailure;
    expect(error.offline, isTrue);
  });

  test('HttpException maps to NetworkFailure', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenThrow(const HttpException('bad response'));

    final result = await apiClient.getBinanceJson<Object?>(
      path: '/api/v3/ping',
      decode: (json) => json,
    );

    expect((result as Failure).error, isA<NetworkFailure>());
  });
}
