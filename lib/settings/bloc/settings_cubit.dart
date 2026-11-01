import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/settings/bloc/settings_state.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

/// Manages theme, locale, and display currency preferences.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a cubit backed by [repository].
  SettingsCubit({required SettingsRepository repository})
    : _repository = repository,
      super(const SettingsState.initial());

  final SettingsRepository _repository;

  /// Loads persisted preferences on startup.
  Future<void> load() async {
    final prefs = await _repository.load();
    emit(state.copyWith(preferences: prefs));
  }

  /// Updates theme mode and persists.
  Future<void> setThemeMode(ThemeMode mode) async {
    final next = state.preferences.copyWith(themeMode: mode);
    await _repository.save(next);
    emit(state.copyWith(preferences: next));
  }

  /// Updates locale code (`en` or `sr_Latn`) and persists.
  Future<void> setLocaleCode(String localeCode) async {
    final next = state.preferences.copyWith(localeCode: localeCode);
    await _repository.save(next);
    emit(state.copyWith(preferences: next));
  }

  /// Updates display currency and persists.
  Future<void> setDisplayCurrency(DisplayCurrency currency) async {
    final next = state.preferences.copyWith(displayCurrency: currency);
    await _repository.save(next);
    emit(state.copyWith(preferences: next));
  }

  /// Clears TTL cache via repository.
  Future<void> clearCache() async {
    await _repository.clearCache();
    emit(state.copyWith(cacheClearMessage: true));
  }
}
