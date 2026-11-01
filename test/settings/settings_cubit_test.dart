import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/storage/preferences_store.dart';
import 'package:pulse/core/time/clock.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository repository;
  late SettingsCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_settings_cubit');
    await HiveBoxes.init(path: tempDir.path);
    repository = SettingsRepository(
      preferencesStore: PreferencesStore(
        settingsBox: Hive.box<String>(HiveBoxes.pulseSettings),
      ),
      cacheStore: CacheStore(
        cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
        clock: const SystemClock(),
      ),
    );
    cubit = SettingsCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('load and persist theme mode', () async {
    await cubit.load();
    await cubit.setThemeMode(ThemeMode.light);
    expect(cubit.state.preferences.themeMode, ThemeMode.light);

    final reloaded = SettingsRepository(
      preferencesStore: PreferencesStore(
        settingsBox: Hive.box<String>(HiveBoxes.pulseSettings),
      ),
      cacheStore: CacheStore(
        cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
        clock: const SystemClock(),
      ),
    );
    final prefs = await reloaded.load();
    expect(prefs.themeMode, ThemeMode.light);
  });

  test('persists display currency', () async {
    await cubit.load();
    await cubit.setDisplayCurrency(DisplayCurrency.usd);
    final prefs = await repository.load();
    expect(prefs.displayCurrency, DisplayCurrency.usd);
  });
}
