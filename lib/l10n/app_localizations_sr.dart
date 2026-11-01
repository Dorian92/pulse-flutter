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

  @override
  String get liveIndicatorLabel => 'UŽIVO';

  @override
  String offlineBannerMessage(int minutes) {
    return 'Offline — prikazujemo cene od pre $minutes min';
  }

  @override
  String get noLiveFeedBadge => 'Nema live feeda';

  @override
  String get globalMarketCapLabel => 'Globalna tržišna kapitalizacija';

  @override
  String get filterAll => 'Sve';

  @override
  String get filterGainers => 'Rast';

  @override
  String get filterLosers => 'Pad';

  @override
  String get filterWatchlist => 'Lista praćenja';

  @override
  String get periodOneDay => '1D';

  @override
  String get periodOneWeek => '1N';

  @override
  String get periodOneMonth => '1M';

  @override
  String get periodThreeMonths => '3M';

  @override
  String get periodOneYear => '1G';

  @override
  String get statMarketCap => 'Tržišna kap';

  @override
  String get statVolume24h => 'Obim 24h';

  @override
  String get statHigh24h => 'Max 24h';

  @override
  String get statLow24h => 'Min 24h';

  @override
  String get statCirculatingSupply => 'Optičenje u opticaju';

  @override
  String get statAllTimeHigh => 'Svevremenski max';

  @override
  String get watchlistEdit => 'Izmeni';

  @override
  String get watchlistEmptyHint => 'Dodajte imovinu da je pratite ovde.';

  @override
  String get designGalleryTitle => 'Galerija dizajna';

  @override
  String get designGalleryOpen => 'Otvori galeriju dizajna';

  @override
  String get designGalleryThemeToggle => 'Promeni temu';

  @override
  String get designGallerySectionComponents => 'Komponente';

  @override
  String get designGalleryChartDeferred =>
      'Interaktivni grafikon stiže u koraku detalja koina.';

  @override
  String get designGalleryTriggerFlash => 'Pokreni live flash';

  @override
  String get removeActionLabel => 'Ukloni';
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

  @override
  String get liveIndicatorLabel => 'UŽIVO';

  @override
  String offlineBannerMessage(int minutes) {
    return 'Offline — prikazujemo cene od pre $minutes min';
  }

  @override
  String get noLiveFeedBadge => 'Nema live feeda';

  @override
  String get globalMarketCapLabel => 'Globalna tržišna kapitalizacija';

  @override
  String get filterAll => 'Sve';

  @override
  String get filterGainers => 'Rast';

  @override
  String get filterLosers => 'Pad';

  @override
  String get filterWatchlist => 'Lista praćenja';

  @override
  String get periodOneDay => '1D';

  @override
  String get periodOneWeek => '1N';

  @override
  String get periodOneMonth => '1M';

  @override
  String get periodThreeMonths => '3M';

  @override
  String get periodOneYear => '1G';

  @override
  String get statMarketCap => 'Tržišna kap';

  @override
  String get statVolume24h => 'Obim 24h';

  @override
  String get statHigh24h => 'Max 24h';

  @override
  String get statLow24h => 'Min 24h';

  @override
  String get statCirculatingSupply => 'Optičenje u opticaju';

  @override
  String get statAllTimeHigh => 'Svevremenski max';

  @override
  String get watchlistEdit => 'Izmeni';

  @override
  String get watchlistEmptyHint => 'Dodajte imovinu da je pratite ovde.';

  @override
  String get designGalleryTitle => 'Galerija dizajna';

  @override
  String get designGalleryOpen => 'Otvori galeriju dizajna';

  @override
  String get designGalleryThemeToggle => 'Promeni temu';

  @override
  String get designGallerySectionComponents => 'Komponente';

  @override
  String get designGalleryChartDeferred =>
      'Interaktivni grafikon stiže u koraku detalja koina.';

  @override
  String get designGalleryTriggerFlash => 'Pokreni live flash';

  @override
  String get removeActionLabel => 'Ukloni';
}
