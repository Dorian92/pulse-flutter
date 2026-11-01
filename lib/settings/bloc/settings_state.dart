import 'package:equatable/equatable.dart';
import 'package:pulse/settings/models/user_preferences.dart';

/// State for [SettingsCubit].
class SettingsState extends Equatable {
  /// Creates settings state.
  const SettingsState({required this.preferences, this.cacheClearMessage});

  /// Initial state before Hive load completes.
  const SettingsState.initial()
    : preferences = UserPreferences.defaults,
      cacheClearMessage = null;

  /// Active user preferences applied to the app shell.
  final UserPreferences preferences;

  /// One-shot flag after cache clear (UI snackbar).
  final bool? cacheClearMessage;

  SettingsState copyWith({
    UserPreferences? preferences,
    bool? cacheClearMessage,
    bool clearCacheClearMessage = false,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      cacheClearMessage: clearCacheClearMessage
          ? null
          : (cacheClearMessage ?? this.cacheClearMessage),
    );
  }

  @override
  List<Object?> get props => [preferences, cacheClearMessage];
}
