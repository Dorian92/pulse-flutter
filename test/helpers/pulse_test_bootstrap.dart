import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/markets/models/global_market_summary.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/core/error/result.dart';

class MockMarketsRepository extends Mock implements MarketsRepository {}

/// Boots Hive + get_it the same way as [main], with a stub markets repo.
Future<void> initPulseTestDependencies() async {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  await configureDependencies(marketsRepository: marketsRepository);
}
