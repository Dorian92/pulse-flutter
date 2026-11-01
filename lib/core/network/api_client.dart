import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pulse/core/config/api_keys.dart';
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_exception.dart';
import 'package:pulse/core/time/clock.dart';

/// Which upstream API base URL to use.
enum ApiBase {
  /// CoinGecko Demo REST (`AppConfig.coinGeckoBaseUrl`).
  coinGecko,

  /// Binance Spot REST (`AppConfig.binanceBaseUrl`).
  binance,
}

/// HTTP client wrapper with timeouts, JSON decode, retries, and [AppFailure] mapping.
class ApiClient {
  /// Creates an API client.
  ApiClient({
    required http.Client httpClient,
    required AppConfig config,
    required Clock clock,
    void Function(String message)? log,
  }) : _httpClient = httpClient,
       _config = config,
       _clock = clock,
       _log = log ?? _debugLog;

  final http.Client _httpClient;
  final AppConfig _config;
  final Clock _clock;
  final void Function(String message) _log;

  /// Performs a GET returning decoded JSON as [Result].
  Future<Result<T>> getJson<T>({
    required ApiBase base,
    required String path,
    required T Function(Object? json) decode,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    int? maxAttempts,
  }) async {
    final uri = _buildUri(base, path, queryParameters);
    final attempts = maxAttempts ?? _config.apiMaxAttempts;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await _httpClient
            .get(uri, headers: headers)
            .timeout(
              _config.connectTimeout + _config.receiveTimeout,
              onTimeout: () {
                throw ApiException(const TimeoutFailure());
              },
            );

        _log('GET ${uri.path} → ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final decoded = json.decode(response.body);
            return Success(decode(decoded));
          } on Object catch (error) {
            return Failure(ParsingFailure(cause: error));
          }
        }

        final failure = _failureForStatus(
          response.statusCode,
          response.headers,
        );
        if (_shouldRetry(failure, attempt, attempts)) {
          await _delayBeforeRetry(failure, attempt);
          continue;
        }
        return Failure(failure);
      } on ApiException catch (error) {
        if (_shouldRetry(error.failure, attempt, attempts)) {
          await _delayBeforeRetry(error.failure, attempt);
          continue;
        }
        return Failure(error.failure);
      } on SocketException {
        const failure = NetworkFailure(offline: true);
        if (_shouldRetry(failure, attempt, attempts)) {
          await _delayBeforeRetry(failure, attempt);
          continue;
        }
        return const Failure(NetworkFailure(offline: true));
      } on HttpException catch (error) {
        const failure = NetworkFailure();
        if (_shouldRetry(failure, attempt, attempts)) {
          await _delayBeforeRetry(failure, attempt);
          continue;
        }
        return Failure(UnknownFailure(cause: error));
      } on TimeoutException {
        const failure = TimeoutFailure();
        if (_shouldRetry(failure, attempt, attempts)) {
          await _delayBeforeRetry(failure, attempt);
          continue;
        }
        return const Failure(TimeoutFailure());
      } on Object catch (error) {
        return Failure(UnknownFailure(cause: error));
      }
    }

    return const Failure(UnknownFailure());
  }

  /// CoinGecko GET with Demo API key header when configured.
  Future<Result<T>> getCoinGeckoJson<T>({
    required String path,
    required T Function(Object? json) decode,
    Map<String, String>? queryParameters,
    int? maxAttempts,
  }) {
    final headers = <String, String>{};
    final key = ApiKeys.coinGeckoDemoApiKey;
    if (key.isNotEmpty) {
      headers['x-cg-demo-api-key'] = key;
    }
    return getJson(
      base: ApiBase.coinGecko,
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      decode: decode,
      maxAttempts: maxAttempts,
    );
  }

  /// Binance Spot GET (no auth).
  Future<Result<T>> getBinanceJson<T>({
    required String path,
    required T Function(Object? json) decode,
    Map<String, String>? queryParameters,
    int? maxAttempts,
  }) {
    return getJson(
      base: ApiBase.binance,
      path: path,
      queryParameters: queryParameters,
      decode: decode,
      maxAttempts: maxAttempts,
    );
  }

  Uri _buildUri(
    ApiBase base,
    String path,
    Map<String, String>? queryParameters,
  ) {
    final root = switch (base) {
      ApiBase.coinGecko => _config.coinGeckoBaseUrl,
      ApiBase.binance => _config.binanceBaseUrl,
    };
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$normalizedPath').replace(
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
    );
  }

  AppFailure _failureForStatus(int statusCode, Map<String, String> headers) {
    if (statusCode == 404) {
      return NotFoundFailure(statusCode: statusCode);
    }
    if (statusCode == 429) {
      return RateLimitFailure(retryAfterSeconds: _parseRetryAfter(headers));
    }
    if (statusCode == 418 || statusCode >= 500) {
      return ServerFailure(statusCode: statusCode);
    }
    if (statusCode == 401 || statusCode == 403) {
      return ServerFailure(statusCode: statusCode);
    }
    if (statusCode >= 400) {
      return UnknownFailure(cause: 'HTTP $statusCode');
    }
    return UnknownFailure(cause: 'HTTP $statusCode');
  }

  int? _parseRetryAfter(Map<String, String> headers) {
    final value = headers['retry-after'] ?? headers['Retry-After'];
    if (value == null) {
      return null;
    }
    final asInt = int.tryParse(value.trim());
    if (asInt != null) {
      return asInt;
    }
    try {
      final date = HttpDate.parse(value);
      final seconds = date.difference(_clock.now()).inSeconds;
      return seconds > 0 ? seconds : 0;
    } on Object {
      return null;
    }
  }

  bool _shouldRetry(AppFailure failure, int attempt, int maxAttempts) {
    if (attempt >= maxAttempts - 1) {
      return false;
    }
    return switch (failure) {
      TimeoutFailure() => true,
      NetworkFailure() => true,
      ServerFailure(:final statusCode) =>
        statusCode == 502 || statusCode == 503 || statusCode == 504,
      RateLimitFailure() => true,
      _ => false,
    };
  }

  Future<void> _delayBeforeRetry(AppFailure failure, int attempt) async {
    final retryAfter = failure is RateLimitFailure
        ? failure.retryAfterSeconds
        : null;
    if (retryAfter != null && retryAfter > 0) {
      await Future<void>.delayed(Duration(seconds: retryAfter));
      return;
    }
    final backoffMs = 500 * (1 << attempt);
    await Future<void>.delayed(Duration(milliseconds: backoffMs));
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'ApiClient');
    }
  }
}
