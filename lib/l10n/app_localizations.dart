import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sr'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get appTitle;

  /// No description provided for @tabMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get tabMarkets;

  /// No description provided for @tabWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get tabWatchlist;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @marketsPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get marketsPlaceholderTitle;

  /// No description provided for @marketsPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Top coins and live prices will appear here.'**
  String get marketsPlaceholderBody;

  /// No description provided for @watchlistPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistPlaceholderTitle;

  /// No description provided for @watchlistPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved coins will appear here.'**
  String get watchlistPlaceholderBody;

  /// No description provided for @settingsPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPlaceholderTitle;

  /// No description provided for @settingsPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, and currency preferences will appear here.'**
  String get settingsPlaceholderBody;

  /// No description provided for @coinDetailPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Coin detail'**
  String get coinDetailPlaceholderTitle;

  /// No description provided for @coinDetailPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Charts and stats for {coinId} will appear here.'**
  String coinDetailPlaceholderBody(String coinId);

  /// No description provided for @liveIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveIndicatorLabel;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing prices from {minutes} min ago'**
  String offlineBannerMessage(int minutes);

  /// No description provided for @noLiveFeedBadge.
  ///
  /// In en, this message translates to:
  /// **'No live feed'**
  String get noLiveFeedBadge;

  /// No description provided for @globalMarketCapLabel.
  ///
  /// In en, this message translates to:
  /// **'Global market cap'**
  String get globalMarketCapLabel;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterGainers.
  ///
  /// In en, this message translates to:
  /// **'Gainers'**
  String get filterGainers;

  /// No description provided for @filterLosers.
  ///
  /// In en, this message translates to:
  /// **'Losers'**
  String get filterLosers;

  /// No description provided for @filterWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get filterWatchlist;

  /// No description provided for @periodOneDay.
  ///
  /// In en, this message translates to:
  /// **'1D'**
  String get periodOneDay;

  /// No description provided for @periodOneWeek.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get periodOneWeek;

  /// No description provided for @periodOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get periodOneMonth;

  /// No description provided for @periodThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get periodThreeMonths;

  /// No description provided for @periodOneYear.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get periodOneYear;

  /// No description provided for @statMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get statMarketCap;

  /// No description provided for @statVolume24h.
  ///
  /// In en, this message translates to:
  /// **'24h volume'**
  String get statVolume24h;

  /// No description provided for @statHigh24h.
  ///
  /// In en, this message translates to:
  /// **'24h high'**
  String get statHigh24h;

  /// No description provided for @statLow24h.
  ///
  /// In en, this message translates to:
  /// **'24h low'**
  String get statLow24h;

  /// No description provided for @statCirculatingSupply.
  ///
  /// In en, this message translates to:
  /// **'Circulating supply'**
  String get statCirculatingSupply;

  /// No description provided for @statAllTimeHigh.
  ///
  /// In en, this message translates to:
  /// **'All-time high'**
  String get statAllTimeHigh;

  /// No description provided for @watchlistEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get watchlistEdit;

  /// No description provided for @watchlistDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get watchlistDone;

  /// No description provided for @watchlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add assets to track them here.'**
  String get watchlistEmptyHint;

  /// No description provided for @watchlistBrowseMarkets.
  ///
  /// In en, this message translates to:
  /// **'Browse markets'**
  String get watchlistBrowseMarkets;

  /// No description provided for @watchlistUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get watchlistUndo;

  /// No description provided for @watchlistUnavailableCoin.
  ///
  /// In en, this message translates to:
  /// **'Price data unavailable'**
  String get watchlistUnavailableCoin;

  /// No description provided for @watchlistRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed {coinName} from watchlist'**
  String watchlistRemovedSnackbar(String coinName);

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSerbian.
  ///
  /// In en, this message translates to:
  /// **'Srpski (latinica)'**
  String get settingsLanguageSerbian;

  /// No description provided for @settingsCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get settingsCurrencySection;

  /// No description provided for @settingsCurrencyEur.
  ///
  /// In en, this message translates to:
  /// **'Euro (EUR)'**
  String get settingsCurrencyEur;

  /// No description provided for @settingsCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar (USD)'**
  String get settingsCurrencyUsd;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataSection;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cached market data'**
  String get settingsClearCache;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsGitHub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get settingsGitHub;

  /// No description provided for @designGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Design gallery'**
  String get designGalleryTitle;

  /// No description provided for @designGalleryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open design gallery'**
  String get designGalleryOpen;

  /// No description provided for @designGalleryThemeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get designGalleryThemeToggle;

  /// No description provided for @designGallerySectionComponents.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get designGallerySectionComponents;

  /// No description provided for @designGalleryChartDeferred.
  ///
  /// In en, this message translates to:
  /// **'Interactive price chart ships in coin detail step.'**
  String get designGalleryChartDeferred;

  /// No description provided for @designGalleryTriggerFlash.
  ///
  /// In en, this message translates to:
  /// **'Trigger live flash'**
  String get designGalleryTriggerFlash;

  /// No description provided for @removeActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeActionLabel;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorOffline;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errorRateLimit;

  /// No description provided for @errorRateLimitRetryAfter.
  ///
  /// In en, this message translates to:
  /// **'Rate limited. Try again in {seconds} seconds.'**
  String errorRateLimitRetryAfter(int seconds);

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The service is unavailable right now. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorParsing.
  ///
  /// In en, this message translates to:
  /// **'Could not read the server response.'**
  String get errorParsing;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That item could not be found.'**
  String get errorNotFound;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'Local storage error. Try refreshing the data.'**
  String get errorCache;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @marketsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search coins'**
  String get marketsSearchHint;

  /// No description provided for @marketsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get marketsRetry;

  /// No description provided for @marketsEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No coins match this filter.'**
  String get marketsEmptyFilter;

  /// No description provided for @marketsNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No coins match your search.'**
  String get marketsNoSearchResults;

  /// No description provided for @coinDetailAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get coinDetailAboutTitle;

  /// No description provided for @coinDetailChartError.
  ///
  /// In en, this message translates to:
  /// **'Chart could not be loaded.'**
  String get coinDetailChartError;

  /// No description provided for @coinDetailAddWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get coinDetailAddWatchlist;

  /// No description provided for @coinDetailRemoveWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get coinDetailRemoveWatchlist;

  /// No description provided for @statUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get statUnknown;

  /// No description provided for @coinDetailChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough chart data for this range.'**
  String get coinDetailChartEmpty;

  /// No description provided for @coinDetailHomepageLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get coinDetailHomepageLabel;

  /// No description provided for @coinDetailHomepageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get coinDetailHomepageCopy;

  /// No description provided for @coinDetailHomepageCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get coinDetailHomepageCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsSrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
