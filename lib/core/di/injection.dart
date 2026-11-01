import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository_impl.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_local_data_source.dart';
import 'package:pulse/coin_detail/repository/data_sources/coin_detail_remote_data_source.dart';
import 'package:pulse/coin_detail/watchlist/watchlist_toggle.dart';
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/connectivity/connectivity_plus_service.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/network/pulse_http_client.dart';
import 'package:pulse/core/realtime/binance_price_stream_service.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/realtime/symbol_mapper_loader.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/storage/preferences_store.dart';
import 'package:pulse/core/time/clock.dart';
import 'package:pulse/markets/repository/data_sources/markets_local_data_source.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/markets/repository/markets_repository_impl.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_local_data_source.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_markets_data_source.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';
import 'package:pulse/watchlist/repository/watchlist_repository_impl.dart';
import 'package:pulse/watchlist/watchlist_toggle_adapter.dart';

/// Global service locator (composition root only).
final GetIt sl = GetIt.instance;

/// Registers core dependencies. Call after [HiveBoxes.init].
///
/// Intended to run once per process (from [main] or tests). Calling again without
/// [resetDependencies] is a no-op: the first registration wins and later
/// overrides are ignored. Tests must call [resetDependencies] before re-configuring.
Future<void> configureDependencies({
  AppConfig? appConfig,
  http.Client? httpClient,
  ConnectivityService? connectivityService,
  Clock? clock,
  CacheStore? cacheStore,
  SymbolMapper? symbolMapper,
  MarketsRepository? marketsRepository,
  PriceStreamService? priceStreamService,
  RealtimeSubscriptionCoordinator? subscriptionCoordinator,
  CoinDetailRepository? coinDetailRepository,
  WatchlistToggle? watchlistToggle,
}) async {
  if (!sl.isRegistered<AppConfig>()) {
    sl.registerSingleton<AppConfig>(appConfig ?? const AppConfig());
  }
  if (!sl.isRegistered<Clock>()) {
    sl.registerSingleton<Clock>(clock ?? const SystemClock());
  }
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(
      () => httpClient ?? createPulseHttpClient(sl<AppConfig>()),
      dispose: (client) => client.close(),
    );
  }
  if (!sl.isRegistered<ConnectivityService>()) {
    sl.registerLazySingleton<ConnectivityService>(
      () => connectivityService ?? ConnectivityPlusService(),
    );
  }
  if (!sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ApiClient>(
      () => ApiClient(
        httpClient: sl<http.Client>(),
        config: sl<AppConfig>(),
        clock: sl<Clock>(),
      ),
    );
  }
  if (!sl.isRegistered<CacheStore>()) {
    sl.registerLazySingleton<CacheStore>(
      () =>
          cacheStore ??
          CacheStore(
            cacheBox: Hive.box<String>(HiveBoxes.pulseCache),
            clock: sl<Clock>(),
          ),
    );
  }
  if (!sl.isRegistered<SymbolMapper>()) {
    sl.registerSingleton<SymbolMapper>(symbolMapper ?? SymbolMapper());
  }
  _registerSettings();
  _registerRealtime(
    priceStreamService: priceStreamService,
    subscriptionCoordinator: subscriptionCoordinator,
  );
  _registerMarkets(marketsRepository: marketsRepository);
  _registerWatchlist();
  _registerCoinDetail(
    coinDetailRepository: coinDetailRepository,
    watchlistToggle: watchlistToggle,
  );
}

void _registerRealtime({
  PriceStreamService? priceStreamService,
  RealtimeSubscriptionCoordinator? subscriptionCoordinator,
}) {
  if (!sl.isRegistered<PriceStreamService>()) {
    sl.registerLazySingleton<PriceStreamService>(
      () =>
          priceStreamService ??
          BinancePriceStreamService(config: sl<AppConfig>()),
      dispose: (service) => service.dispose(),
    );
  }
  if (!sl.isRegistered<RealtimeSubscriptionCoordinator>()) {
    sl.registerLazySingleton<RealtimeSubscriptionCoordinator>(
      () =>
          subscriptionCoordinator ??
          RealtimeSubscriptionCoordinator(sl<PriceStreamService>()),
    );
  }
  if (!sl.isRegistered<SymbolMapperLoader>()) {
    sl.registerLazySingleton<SymbolMapperLoader>(
      () => SymbolMapperLoader(
        apiClient: sl<ApiClient>(),
        cacheStore: sl<CacheStore>(),
        symbolMapper: sl<SymbolMapper>(),
      ),
    );
  }
}

void _registerSettings() {
  if (!sl.isRegistered<PreferencesStore>()) {
    sl.registerLazySingleton<PreferencesStore>(
      () => PreferencesStore(
        settingsBox: Hive.box<String>(HiveBoxes.pulseSettings),
      ),
    );
  }
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepository(
        preferencesStore: sl<PreferencesStore>(),
        cacheStore: sl<CacheStore>(),
      ),
    );
  }
}

void _registerWatchlist() {
  if (!sl.isRegistered<WatchlistLocalDataSource>()) {
    sl.registerLazySingleton<WatchlistLocalDataSource>(
      () => WatchlistLocalDataSource(
        persistBox: Hive.box<String>(HiveBoxes.pulsePersist),
      ),
    );
  }
  if (!sl.isRegistered<WatchlistMarketsDataSource>()) {
    sl.registerLazySingleton<WatchlistMarketsDataSource>(
      () => WatchlistMarketsDataSource(
        apiClient: sl<ApiClient>(),
        symbolMapper: sl<SymbolMapper>(),
        cacheStore: sl<CacheStore>(),
        settingsRepository: sl<SettingsRepository>(),
      ),
    );
  }
  if (!sl.isRegistered<WatchlistRepository>()) {
    sl.registerLazySingleton<WatchlistRepository>(
      () => WatchlistRepositoryImpl(
        local: sl<WatchlistLocalDataSource>(),
        marketsRepository: sl<MarketsRepository>(),
        supplementalMarkets: sl<WatchlistMarketsDataSource>(),
        connectivity: sl<ConnectivityService>(),
      ),
    );
  }
}

void _registerMarkets({MarketsRepository? marketsRepository}) {
  if (sl.isRegistered<MarketsRepository>()) {
    return;
  }
  sl.registerLazySingleton<MarketsRemoteDataSource>(
    () => MarketsRemoteDataSource(
      apiClient: sl<ApiClient>(),
      symbolMapper: sl<SymbolMapper>(),
      clock: sl<Clock>(),
      settingsRepository: sl<SettingsRepository>(),
    ),
  );
  sl.registerLazySingleton<MarketsLocalDataSource>(
    () => MarketsLocalDataSource(cacheStore: sl<CacheStore>()),
  );
  if (marketsRepository != null) {
    sl.registerLazySingleton<MarketsRepository>(() => marketsRepository);
    return;
  }
  sl.registerLazySingleton<MarketsRepository>(
    () => MarketsRepositoryImpl(
      remote: sl<MarketsRemoteDataSource>(),
      local: sl<MarketsLocalDataSource>(),
      connectivity: sl<ConnectivityService>(),
      settingsRepository: sl<SettingsRepository>(),
    ),
  );
}

void _registerCoinDetail({
  CoinDetailRepository? coinDetailRepository,
  WatchlistToggle? watchlistToggle,
}) {
  if (!sl.isRegistered<WatchlistToggle>()) {
    sl.registerLazySingleton<WatchlistToggle>(
      () =>
          watchlistToggle ??
          WatchlistRepositoryToggle(sl<WatchlistRepository>()),
    );
  }
  if (sl.isRegistered<CoinDetailRepository>()) {
    return;
  }
  sl.registerLazySingleton<CoinDetailRemoteDataSource>(
    () => CoinDetailRemoteDataSource(
      apiClient: sl<ApiClient>(),
      symbolMapper: sl<SymbolMapper>(),
      clock: sl<Clock>(),
    ),
  );
  sl.registerLazySingleton<CoinDetailLocalDataSource>(
    () => CoinDetailLocalDataSource(cacheStore: sl<CacheStore>()),
  );
  if (coinDetailRepository != null) {
    sl.registerLazySingleton<CoinDetailRepository>(() => coinDetailRepository);
    return;
  }
  sl.registerLazySingleton<CoinDetailRepository>(
    () => CoinDetailRepositoryImpl(
      remote: sl<CoinDetailRemoteDataSource>(),
      local: sl<CoinDetailLocalDataSource>(),
      connectivity: sl<ConnectivityService>(),
    ),
  );
}

/// Clears registrations (for tests).
Future<void> resetDependencies() async {
  await sl.reset();
}
