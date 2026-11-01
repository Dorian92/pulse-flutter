import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pulse/core/config/api_keys.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/storage/preferences_store.dart';

void main() {
  test('coinGeckoDemoApiKey reads fromEnvironment', () {
    expect(ApiKeys.coinGeckoDemoApiKey, isA<String>());
  });

  group('PreferencesStore', () {
    late Directory tempDir;
    late PreferencesStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pulse_prefs_test');
      await HiveBoxes.init(path: tempDir.path);
      store = PreferencesStore(
        settingsBox: Hive.box<String>(HiveBoxes.pulseSettings),
      );
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('writeJson round-trips readJson', () async {
      await store.writeJson({'themeMode': 'dark', 'localeCode': 'en'});
      final json = await store.readJson();
      expect(json?['themeMode'], 'dark');
    });

    test('drops corrupt JSON', () async {
      final box = Hive.box<String>(HiveBoxes.pulseSettings);
      await box.put(PreferencesStore.settingsKey, 'not-json');
      expect(await store.readJson(), isNull);
      expect(box.get(PreferencesStore.settingsKey), isNull);
    });
  });
}
