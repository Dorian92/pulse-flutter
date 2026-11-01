import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/debug/ui/design_gallery_page.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/settings/ui/settings_page.dart';
import 'package:pulse/shell/ui/main_shell.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

abstract final class AppRoutes {
  static const markets = '/';
  static const watchlist = '/watchlist';
  static const settings = '/settings';
  static const coinDetail = '/coin/:coinId';
  static const designGallery = '/debug/design-gallery';

  static String coinDetailPath(String coinId) => '/coin/$coinId';
}

GoRouter createAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final marketsShellKey = GlobalKey<NavigatorState>(debugLabel: 'marketsShell');
  final watchlistShellKey = GlobalKey<NavigatorState>(
    debugLabel: 'watchlistShell',
  );
  final settingsShellKey = GlobalKey<NavigatorState>(
    debugLabel: 'settingsShell',
  );

  final routes = <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          navigatorKey: marketsShellKey,
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.markets,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MarketsPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: watchlistShellKey,
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.watchlist,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WatchlistPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: settingsShellKey,
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.coinDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final coinId = state.pathParameters['coinId'] ?? '';
        return CoinDetailPage(coinId: coinId);
      },
    ),
  ];

  if (kDebugMode) {
    routes.add(
      GoRoute(
        path: AppRoutes.designGallery,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DesignGalleryPage(),
      ),
    );
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.markets,
    routes: routes,
  );
}
