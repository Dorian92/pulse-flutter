import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/core/theme/app_colors.dart';
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
          body: Row(children: [LiveIndicator(active: false), LiveIndicator()]),
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
        home: const _FlashHarness(initialToken: 1),
      ),
    );

    await tester.pump();
    final tileFinder = find.byKey(const Key('flash-tile'));
    final materialBefore = tester.widget<Material>(
      find.descendant(of: tileFinder, matching: find.byType(Material)),
    );
    expect(materialBefore.color, Colors.transparent);

    await tester.tap(find.text('Bump flash'));
    await tester.pump();

    final materialAfter = tester.widget<Material>(
      find.descendant(of: tileFinder, matching: find.byType(Material)),
    );
    expect(materialAfter.color, isNot(Colors.transparent));
  });

  test('RealtimeLive drives indicator helper', () {
    const status = RealtimeStatus.live();
    expect(status.isLiveIndicatorActive, isTrue);
    expect(const RealtimeStatus.offline().isLiveIndicatorActive, isFalse);
  });
}

class _FlashHarness extends StatefulWidget {
  const _FlashHarness({required this.initialToken});

  final int initialToken;

  @override
  State<_FlashHarness> createState() => _FlashHarnessState();
}

class _FlashHarnessState extends State<_FlashHarness> {
  late int _token;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CoinListTile(
            key: const Key('flash-tile'),
            name: 'Bitcoin',
            symbol: 'btc',
            priceText: '€1',
            changePercent: 1,
            sparklineValues: const [1, 2],
            liveFlashToken: _token,
          ),
          TextButton(
            onPressed: () => setState(() => _token++),
            child: const Text('Bump flash'),
          ),
        ],
      ),
    );
  }
}
