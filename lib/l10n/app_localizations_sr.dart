// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Pulse';

  @override
  String get tabMarkets => 'Tržišta';

  @override
  String get tabWatchlist => 'Lista praćenja';

  @override
  String get tabSettings => 'Podešavanja';

  @override
  String get marketsPlaceholderTitle => 'Tržišta';

  @override
  String get marketsPlaceholderBody =>
      'Ovde će se prikazati vodeći koini i cene uživo.';

  @override
  String get watchlistPlaceholderTitle => 'Lista praćenja';

  @override
  String get watchlistPlaceholderBody => 'Ovde će se prikazati sačuvani koini.';

  @override
  String get settingsPlaceholderTitle => 'Podešavanja';

  @override
  String get settingsPlaceholderBody => 'Ovde će biti tema, jezik i valuta.';

  @override
  String get coinDetailPlaceholderTitle => 'Detalji koina';

  @override
  String coinDetailPlaceholderBody(String coinId) {
    return 'Grafikon i statistika za $coinId biće ovde.';
  }
}

/// The translations for Serbian, using the Latin script (`sr_Latn`).
class AppLocalizationsSrLatn extends AppLocalizationsSr {
  AppLocalizationsSrLatn() : super('sr_Latn');

  @override
  String get appTitle => 'Pulse';

  @override
  String get tabMarkets => 'Tržišta';

  @override
  String get tabWatchlist => 'Lista praćenja';

  @override
  String get tabSettings => 'Podešavanja';

  @override
  String get marketsPlaceholderTitle => 'Tržišta';

  @override
  String get marketsPlaceholderBody =>
      'Ovde će se prikazati vodeći koini i cene uživo.';

  @override
  String get watchlistPlaceholderTitle => 'Lista praćenja';

  @override
  String get watchlistPlaceholderBody => 'Ovde će se prikazati sačuvani koini.';

  @override
  String get settingsPlaceholderTitle => 'Podešavanja';

  @override
  String get settingsPlaceholderBody => 'Ovde će biti tema, jezik i valuta.';

  @override
  String get coinDetailPlaceholderTitle => 'Detalji koina';

  @override
  String coinDetailPlaceholderBody(String coinId) {
    return 'Grafikon i statistika za $coinId biće ovde.';
  }
}
