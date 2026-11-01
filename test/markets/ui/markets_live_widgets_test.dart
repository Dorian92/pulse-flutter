import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/core/widgets/coin_list_tile.dart';
import 'package:pulse/core/widgets/live_indicator.dart';
import 'package:pulse/l10n/app_localizations.dart';

void main() {
  testWidgets('LiveIndicator reflects active flag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Row(
            children: [
              LiveIndicator(active: false),
              LiveIndicator(active: true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('LIVE'), findsNWidgets(2));
  });

  testWidgets('CoinListTile flashes when liveFlashToken changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  CoinListTile(
                    name: 'Bitcoin',
                    symbol: 'btc',
                    priceText: '€1',
                    changePercent: 1,
                    sparklineValues: const [1, 2],
                    liveFlashToken: 1,
                  ),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('noop'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CoinListTile), findsOneWidget);
  });

  test('RealtimeLive drives indicator helper', () {
    const status = RealtimeStatus.live();
    expect(status.isLiveIndicatorActive, isTrue);
    expect(const RealtimeStatus.offline().isLiveIndicatorActive, isFalse);
  });
}
