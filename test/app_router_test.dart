import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app.dart';
import 'package:pulse/coin_detail/ui/coin_detail_page.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/ui/markets_page.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/settings/ui/settings_page.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

import 'helpers/pulse_test_bootstrap.dart';

void main() {
  setUp(() async {
    await initPulseTestDependencies();
  });

  group('PulseApp smoke', () {
    testWidgets('boots and shows markets tab', (tester) async {
      await tester.pumpWidget(const PulseApp());
      await tester.pumpAndSettle();

      expect(find.byType(MarketsPage), findsOneWidget);
      expect(find.text('Markets'), findsWidgets);
    });

    testWidgets('bottom nav switches shell tabs', (tester) async {
      await tester.pumpWidget(const PulseApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();
      expect(find.byType(WatchlistPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.show_chart_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(MarketsPage), findsOneWidget);
    });
  });

  group('App router', () {
    testWidgets('resolves /coin/bitcoin placeholder', (tester) async {
      final router = createAppRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider(
          create: (_) =>
              SettingsCubit(repository: sl<SettingsRepository>())..load(),
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      router.go(AppRoutes.coinDetailPath('bitcoin'));
      await tester.pumpAndSettle();

      expect(find.byType(CoinDetailPage), findsOneWidget);
      expect(find.text('Bitcoin'), findsWidgets);
    });
  });
}
