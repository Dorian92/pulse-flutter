import 'package:equatable/equatable.dart';
import 'package:pulse/settings/models/user_preferences.dart';

/// State for [SettingsCubit].
class SettingsState extends Equatable {
  /// Creates settings state.
  const SettingsState({
    required this.preferences,
    this.cacheClearGeneration = 0,
  });

  /// Initial state before Hive load completes.
  const SettingsState.initial()
    : preferences = UserPreferences.defaults,
      cacheClearGeneration = 0;

  /// Active user preferences applied to the app shell.
  final UserPreferences preferences;

  /// Increments on each cache clear so listeners re-fire.
  final int cacheClearGeneration;

  SettingsState copyWith({
    UserPreferences? preferences,
    int? cacheClearGeneration,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      cacheClearGeneration: cacheClearGeneration ?? this.cacheClearGeneration,
    );
  }

  @override
  List<Object?> get props => [preferences, cacheClearGeneration];
}
