import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/widgets/price_change_pill.dart';
import 'package:pulse/core/widgets/sparkline.dart';

import '../../helpers/pump_pulse.dart';

void main() {
  group('PriceChangePill', () {
    testWidgets('uses gain color for positive change', (tester) async {
      await tester.pumpPulseWidget(const PriceChangePill(changePercent: 2.5));
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PriceChangePill),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, PulseColors.dark.positive);
    });

    testWidgets('uses loss color for negative change', (tester) async {
      await tester.pumpPulseWidget(const PriceChangePill(changePercent: -1.1));
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PriceChangePill),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, PulseColors.dark.negative);
    });
  });

  group('Sparkline', () {
    testWidgets('renders sparkline for trend data', (tester) async {
      await tester.pumpPulseWidget(
        const SizedBox(
          width: 100,
          height: 40,
          child: Sparkline(values: [1, 2, 3, 4]),
        ),
      );
      expect(find.byType(Sparkline), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

// Golden tests for pills/sparklines are intentionally omitted: default CI fonts
// are not deterministic. Re-enable after bundling a test font (see docs/design.md).
