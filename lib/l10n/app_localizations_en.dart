// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pulse';

  @override
  String get tabMarkets => 'Markets';

  @override
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabSettings => 'Settings';

  @override
  String get marketsPlaceholderTitle => 'Markets';

  @override
  String get marketsPlaceholderBody =>
      'Top coins and live prices will appear here.';

  @override
  String get watchlistPlaceholderTitle => 'Watchlist';

  @override
  String get watchlistPlaceholderBody => 'Your saved coins will appear here.';

  @override
  String get settingsPlaceholderTitle => 'Settings';

  @override
  String get settingsPlaceholderBody =>
      'Theme, language, and currency preferences will appear here.';

  @override
  String get coinDetailPlaceholderTitle => 'Coin detail';

  @override
  String coinDetailPlaceholderBody(String coinId) {
    return 'Charts and stats for $coinId will appear here.';
  }
}
