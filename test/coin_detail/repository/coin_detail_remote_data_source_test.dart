import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/settings/models/user_preferences.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

import '../../core/time/fake_clock.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockApiClient apiClient;
  late MockSettingsRepository settings;
  late CoinDetailRemoteDataSource remote;
  late FakeClock clock;

  setUp(() {
    apiClient = MockApiClient();
    settings = MockSettingsRepository();
    clock = FakeClock();
    when(() => settings.current).thenReturn(UserPreferences.defaults);
    remote = CoinDetailRemoteDataSource(
      apiClient: apiClient,
      symbolMapper: SymbolMapper(),
      clock: clock,
      settingsRepository: settings,
    );
  });

  test('parseCoinDetailFromApi leaves missing stats null', () async {
    final raw = await File(
      'test/coin_detail/fixtures/coingecko_coin_bitcoin.json',
    ).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    (json['market_data'] as Map<String, dynamic>).remove('market_cap');

    final detail = parseCoinDetailFromApi(
      json,
      coinId: 'bitcoin',
      symbolMapper: SymbolMapper(),
      fetchedAt: clock.now(),
    );

    expect(detail.marketCapEur, isNull);
    expect(detail.currentPriceEur, 65000.5);
  });

  test('fetchChart uses Binance klines when pair exists', () async {
    when(
      () => apiClient.getBinanceJson<double>(
        path: '/api/v3/ticker/price',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode] as double Function(Object? json);
      return Success(decode({'price': '1.05'}));
    });

    when(
      () => apiClient.getBinanceJson<List<dynamic>>(
        path: '/api/v3/klines',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as List<dynamic> Function(Object? json);
      return Success(
        decode([
          [
            1700000000000,
            '64000',
            '64500',
            '63900',
            '64200',
            '100',
            1700003599999,
            '0',
            0,
            '0',
            '0',
            '0',
          ],
          [
            1700003600000,
            '64200',
            '65000',
            '64100',
            '64800',
            '100',
            1700007199999,
            '0',
            0,
            '0',
            '0',
            '0',
          ],
        ]),
      );
    });

    final result = await remote.fetchChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneDay,
      binanceSymbol: 'BTCUSDT',
    );

    expect(result, isA<Success<PriceChartSeries>>());
    final series = (result as Success).value as PriceChartSeries;
    expect(series.source, ChartDataSource.binanceKlines);
    expect(series.points.length, 2);
    expect(series.points.first.priceEur, closeTo(64200 / 1.05, 0.01));
  });

  test('fetchChart falls back to CoinGecko when Binance klines fail', () async {
    when(
      () => apiClient.getBinanceJson<double>(
        path: '/api/v3/ticker/price',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode] as double Function(Object? json);
      return Success(decode({'price': '1.05'}));
    });

    when(
      () => apiClient.getBinanceJson<List<dynamic>>(
        path: '/api/v3/klines',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(ServerFailure()));

    when(
      () => apiClient.getCoinGeckoJson<PriceChartSeries>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as PriceChartSeries Function(Object? json);
      return Success(
        decode({
          'prices': [
            [1, 100.0],
            [2, 101.0],
          ],
        }),
      );
    });

    final result = await remote.fetchChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneWeek,
      binanceSymbol: 'BTCUSDT',
    );

    expect(result, isA<Success<PriceChartSeries>>());
    expect(
      (result as Success).value.source,
      ChartDataSource.coinGeckoMarketChart,
    );
  });

  test('fetchChart returns failure when EURUSDT rate unavailable', () async {
    when(
      () => apiClient.getBinanceJson<double>(
        path: '/api/v3/ticker/price',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkFailure(offline: true)));

    when(
      () => apiClient.getCoinGeckoJson<PriceChartSeries>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(ServerFailure()));

    final result = await remote.fetchChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneDay,
      binanceSymbol: 'BTCUSDT',
    );

    expect(result, isA<Failure<PriceChartSeries>>());
  });

  test('fetchChart returns failure when klines payload empty', () async {
    when(
      () => apiClient.getBinanceJson<double>(
        path: '/api/v3/ticker/price',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode] as double Function(Object? json);
      return Success(decode({'price': '1.05'}));
    });

    when(
      () => apiClient.getBinanceJson<List<dynamic>>(
        path: '/api/v3/klines',
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((invocation) async {
      final decode =
          invocation.namedArguments[#decode]
              as List<dynamic> Function(Object? json);
      return Success(decode([]));
    });

    when(
      () => apiClient.getCoinGeckoJson<PriceChartSeries>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
        decode: any(named: 'decode'),
      ),
    ).thenAnswer((_) async => const Failure(ServerFailure()));

    final result = await remote.fetchChart(
      coinId: 'bitcoin',
      range: ChartPeriod.oneDay,
      binanceSymbol: 'BTCUSDT',
    );

    expect(result, isA<Failure<PriceChartSeries>>());
  });
}
