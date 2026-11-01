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

  @override
  String get liveIndicatorLabel => 'LIVE';

  @override
  String offlineBannerMessage(int minutes) {
    return 'Offline — showing prices from $minutes min ago';
  }

  @override
  String get noLiveFeedBadge => 'No live feed';

  @override
  String get globalMarketCapLabel => 'Global market cap';

  @override
  String get filterAll => 'All';

  @override
  String get filterGainers => 'Gainers';

  @override
  String get filterLosers => 'Losers';

  @override
  String get filterWatchlist => 'Watchlist';

  @override
  String get periodOneDay => '1D';

  @override
  String get periodOneWeek => '1W';

  @override
  String get periodOneMonth => '1M';

  @override
  String get periodThreeMonths => '3M';

  @override
  String get periodOneYear => '1Y';

  @override
  String get statMarketCap => 'Market cap';

  @override
  String get statVolume24h => '24h volume';

  @override
  String get statHigh24h => '24h high';

  @override
  String get statLow24h => '24h low';

  @override
  String get statCirculatingSupply => 'Circulating supply';

  @override
  String get statAllTimeHigh => 'All-time high';

  @override
  String get watchlistEdit => 'Edit';

  @override
  String get watchlistDone => 'Done';

  @override
  String get watchlistEmptyHint => 'Add assets to track them here.';

  @override
  String get watchlistBrowseMarkets => 'Browse markets';

  @override
  String get watchlistUndo => 'Undo';

  @override
  String get watchlistUnavailableCoin => 'Price data unavailable';

  @override
  String watchlistRemovedSnackbar(String coinName) {
    return 'Removed $coinName from watchlist';
  }

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSerbian => 'Srpski (latinica)';

  @override
  String get settingsCurrencySection => 'Display currency';

  @override
  String get settingsCurrencyEur => 'Euro (EUR)';

  @override
  String get settingsCurrencyUsd => 'US dollar (USD)';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsClearCache => 'Clear cached market data';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsGitHub => 'View on GitHub';

  @override
  String get designGalleryTitle => 'Design gallery';

  @override
  String get designGalleryOpen => 'Open design gallery';

  @override
  String get designGalleryThemeToggle => 'Toggle theme';

  @override
  String get designGallerySectionComponents => 'Components';

  @override
  String get designGalleryChartDeferred =>
      'Interactive price chart ships in coin detail step.';

  @override
  String get designGalleryTriggerFlash => 'Trigger live flash';

  @override
  String get removeActionLabel => 'Remove';

  @override
  String get errorOffline =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get errorNetwork =>
      'Network error. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorRateLimit =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String errorRateLimitRetryAfter(int seconds) {
    return 'Rate limited. Try again in $seconds seconds.';
  }

  @override
  String get errorServer =>
      'The service is unavailable right now. Please try again later.';

  @override
  String get errorParsing => 'Could not read the server response.';

  @override
  String get errorNotFound => 'That item could not be found.';

  @override
  String get errorCache => 'Local storage error. Try refreshing the data.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get marketsSearchHint => 'Search coins';

  @override
  String get marketsRetry => 'Try again';

  @override
  String get marketsEmptyFilter => 'No coins match this filter.';

  @override
  String get marketsNoSearchResults => 'No coins match your search.';

  @override
  String get coinDetailAboutTitle => 'About';

  @override
  String get coinDetailChartError => 'Chart could not be loaded.';

  @override
  String get coinDetailAddWatchlist => 'Add to watchlist';

  @override
  String get coinDetailRemoveWatchlist => 'Remove from watchlist';

  @override
  String get statUnknown => '—';

  @override
  String get coinDetailChartEmpty => 'Not enough chart data for this range.';

  @override
  String get coinDetailHomepageLabel => 'Website';

  @override
  String get coinDetailHomepageCopy => 'Copy link';

  @override
  String get coinDetailHomepageCopied => 'Link copied';
}
