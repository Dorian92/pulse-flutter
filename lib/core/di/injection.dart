import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:pulse/core/config/app_config.dart';
import 'package:pulse/core/connectivity/connectivity_plus_service.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/network/pulse_http_client.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/storage/cache_store.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/core/time/clock.dart';
import 'package:pulse/markets/repository/data_sources/markets_local_data_source.dart';
import 'package:pulse/markets/repository/data_sources/markets_remote_data_source.dart';
import 'package:pulse/markets/repository/markets_repository.dart';
import 'package:pulse/markets/repository/markets_repository_impl.dart';

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
    sl.registerSingleton<SymbolMapper>(symbolMapper ?? const SymbolMapper());
  }
  _registerMarkets(marketsRepository: marketsRepository);
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
    ),
  );
}

/// Clears registrations (for tests).
Future<void> resetDependencies() async {
  await sl.reset();
}
