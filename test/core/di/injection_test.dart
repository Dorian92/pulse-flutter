import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await resetDependencies();
    tempDir = await Directory.systemTemp.createTemp('pulse_di_test');
    await HiveBoxes.init(path: tempDir.path);
    await configureDependencies();
  });

  tearDown(() async {
    await resetDependencies();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('registers core services', () {
    expect(sl<ApiClient>(), isA<ApiClient>());
    expect(sl<CacheStore>(), isA<CacheStore>());
    expect(sl<SymbolMapper>(), isA<SymbolMapper>());
  });

  test('allows overrides after reset', () async {
    await resetDependencies();
    await HiveBoxes.openBoxes();
    final custom = SymbolMapper(overrides: {'x': 'YUSDT'});
    await configureDependencies(symbolMapper: custom);
    expect(sl<SymbolMapper>().binanceUsdtSymbolFor(coinGeckoId: 'x'), 'YUSDT');
  });
}
