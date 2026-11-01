import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/l10n/app_localizations.dart';

void main() {
  testWidgets('English and Serbian Latin localizations load', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.watchlistEmptyHint);
          },
        ),
      ),
    );
    expect(find.text('Add assets to track them here.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale.fromSubtags(
          languageCode: 'sr',
          scriptCode: 'Latn',
        ),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsThemeDark),
                Text(l10n.watchlistEdit),
                Text(l10n.settingsCurrencyEur),
                Text(l10n.settingsClearCache),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tamna'), findsOneWidget);
    expect(find.text('Izmeni'), findsOneWidget);
    expect(find.text('Evro (EUR)'), findsOneWidget);
    expect(find.text('Obriši keširane podatke'), findsOneWidget);
  });
}
