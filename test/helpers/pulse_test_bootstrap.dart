import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/coin_detail/models/price_chart_series.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

class MockMarketsRepository extends Mock implements MarketsRepository {}

class MockCoinDetailRepository extends Mock implements CoinDetailRepository {}

/// Boots Hive + get_it the same way as [main], with a stub markets repo.
Future<void> initPulseTestDependencies() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(ChartPeriod.oneDay);
  registerFallbackValue('bitcoin');
  await resetDependencies();
  final tempDir = await Directory.systemTemp.createTemp('pulse_widget_test');
  addTearDown(() async {
    await resetDependencies();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });
  await HiveBoxes.init(path: tempDir.path);
  final marketsRepository = MockMarketsRepository();
  when(() => marketsRepository.loadMarkets()).thenAnswer(
    (_) async => Success(
      MarketsSnapshot(
        fetchedAt: DateTime.utc(2026, 6, 1, 12),
        global: const GlobalMarketSummary(
          totalMarketCapEur: 100,
          marketCapChangePercent24h: 1,
        ),
        coins: const [
          MarketCoin(
            id: 'bitcoin',
            symbol: 'btc',
            name: 'Bitcoin',
            imageUrl: '',
            currentPriceEur: 1,
            priceChangePercent24h: 1,
            marketCapRank: 1,
            sparkline7d: [1, 2, 3],
            binanceSymbol: 'BTCUSDT',
          ),
        ],
      ),
    ),
  );
  when(
    () => marketsRepository.refreshMarkets(),
  ).thenAnswer((_) async => marketsRepository.loadMarkets());

  final coinDetailRepository = MockCoinDetailRepository();
  when(() => coinDetailRepository.loadDetail(any())).thenAnswer(
    (_) async => Success(
      CoinDetail(
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        imageUrl: '',
        currentPriceEur: 1,
        priceChangePercent24h: 1,
        marketCapEur: 1,
        volume24hEur: 1,
        high24hEur: 1,
        low24hEur: 1,
        circulatingSupply: 1,
        athEur: 1,
        aboutTextEn: 'Test',
        fetchedAt: DateTime.utc(2026, 6),
        binanceSymbol: 'BTCUSDT',
      ),
    ),
  );
  when(
    () => coinDetailRepository.loadChart(
      coinId: any(named: 'coinId'),
      range: any(named: 'range'),
      binanceSymbol: any(named: 'binanceSymbol'),
    ),
  ).thenAnswer(
    (_) async => Success(
      PriceChartSeries(
        points: [
          ChartPoint(timestamp: DateTime.utc(2026, 6), priceEur: 1),
          ChartPoint(timestamp: DateTime.utc(2026, 6, 2), priceEur: 2),
        ],
        range: ChartPeriod.oneDay,
        source: ChartDataSource.coinGeckoMarketChart,
        fetchedAt: DateTime.utc(2026, 6, 2),
      ),
    ),
  );

  await configureDependencies(
    marketsRepository: marketsRepository,
    coinDetailRepository: coinDetailRepository,
  );
  await sl<SettingsRepository>().load();
}
