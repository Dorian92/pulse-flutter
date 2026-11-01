import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pulse/settings/models/display_currency.dart';

/// User-facing app preferences persisted locally.
class UserPreferences extends Equatable {
  /// Creates preferences.
  const UserPreferences({
    required this.themeMode,
    required this.localeCode,
    required this.displayCurrency,
  });

  /// Default preferences on first launch.
  static const UserPreferences defaults = UserPreferences(
    themeMode: ThemeMode.system,
    localeCode: 'en',
    displayCurrency: DisplayCurrency.eur,
  );

  /// Material theme mode.
  final ThemeMode themeMode;

  /// BCP-47 language tag (`en`, `sr_Latn`).
  final String localeCode;

  /// Markets / watchlist quote currency.
  final DisplayCurrency displayCurrency;

  /// Parses from Hive JSON ([schemaVersion] must be checked by caller).
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: _themeModeFromString(json['themeMode'] as String?),
      localeCode: json['localeCode'] as String? ?? defaults.localeCode,
      displayCurrency: DisplayCurrency.fromPersisted(
        json['displayCurrency'] as String?,
      ),
    );
  }

  static ThemeMode _themeModeFromString(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  /// Serializes for [PreferencesStore].
  Map<String, dynamic> toJson({int schemaVersion = 1}) {
    return {
      'schemaVersion': schemaVersion,
      'themeMode': _themeModeToString(themeMode),
      'localeCode': localeCode,
      'displayCurrency': displayCurrency.persistedValue,
    };
  }

  /// Returns a copy with optional overrides.
  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    DisplayCurrency? displayCurrency,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      displayCurrency: displayCurrency ?? this.displayCurrency,
    );
  }

  /// Flutter [Locale] for [MaterialApp.locale].
  Locale get locale {
    if (localeCode == 'sr_Latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    return Locale(localeCode);
  }

  @override
  List<Object?> get props => [themeMode, localeCode, displayCurrency];
}
