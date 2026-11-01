import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/l10n/app_localizations.dart';

extension PumpPulse on WidgetTester {
  Future<void> pumpPulseWidget(
    Widget widget, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: widget,
      ),
    );
    await pumpAndSettle();
  }
}

Future<void> pumpPulseApp(WidgetTester tester) async {
  await tester.pumpWidget(const PulseApp());
  await tester.pumpAndSettle();
}
