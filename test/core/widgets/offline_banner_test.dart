import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/widgets/offline_banner.dart';

import '../../helpers/pump_pulse.dart';

void main() {
  testWidgets('OfflineBanner shows localized stale message', (tester) async {
    await tester.pumpPulseWidget(const OfflineBanner(minutesAgo: 5));
    expect(find.textContaining('5'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });
}
