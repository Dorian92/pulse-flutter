import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';

void main() {
  group('PulseFormatters', () {
    test('formatEurPrice uses euro symbol for en', () {
      final result = PulseFormatters.formatEurPrice(61284.12, 'en');
      expect(result.contains('€'), isTrue);
      expect(result.contains('61'), isTrue);
    });

    test('formatPercentChange adds plus for gains', () {
      expect(PulseFormatters.formatPercentChange(2.41, 'en'), '+2.41%');
    });

    test('formatPercentChange keeps minus for losses', () {
      final result = PulseFormatters.formatPercentChange(-1.2, 'en');
      expect(result.startsWith('-'), isTrue);
      expect(result.endsWith('%'), isTrue);
    });

    test('formatCompactCurrency abbreviates trillions', () {
      final result = PulseFormatters.formatCompactCurrency(2.31e12, 'en');
      expect(result.contains('€'), isTrue);
      expect(result.toLowerCase(), contains('t'));
    });

    test('formatEurPrice respects sr_Latn locale', () {
      final result = PulseFormatters.formatEurPrice(1000.5, 'sr_Latn');
      expect(result.contains('€'), isTrue);
    });
  });
}
