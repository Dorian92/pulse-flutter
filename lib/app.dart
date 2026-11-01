import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/l10n/app_localizations.dart';

class PulseApp extends StatefulWidget {
  const PulseApp({super.key});

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> with WidgetsBindingObserver {
  late final GoRouter _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (sl.isRegistered<PriceStreamService>()) {
      sl<PriceStreamService>().setAppLifecycle(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
