import 'package:intl/intl.dart';
import 'package:pulse/settings/models/display_currency.dart';

/// Locale-aware EUR and market formatting for Pulse UI.
abstract final class PulseFormatters {
  static String formatEurPrice(num value, String locale) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: 'EUR',
      symbol: '€',
      decimalDigits: value >= 1 ? 2 : 4,
    );
    return formatter.format(value);
  }

  static String formatPercentChange(num fraction, String locale) {
    final formatter = NumberFormat.decimalPattern(locale);
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    final sign = fraction >= 0 ? '+' : '';
    return '$sign${formatter.format(fraction)}%';
  }

  static String formatUsdPrice(num value, String locale) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: 'USD',
      symbol: r'$',
      decimalDigits: value >= 1 ? 2 : 4,
    );
    return formatter.format(value);
  }

  static String formatDisplayPrice(
    num value,
    String locale,
    DisplayCurrency currency,
  ) {
    return switch (currency) {
      DisplayCurrency.eur => formatEurPrice(value, locale),
      DisplayCurrency.usd => formatUsdPrice(value, locale),
    };
  }

  static String formatCompactDisplayCurrency(
    num value,
    String locale,
    DisplayCurrency currency,
  ) {
    final name = currency == DisplayCurrency.usd ? 'USD' : 'EUR';
    final symbol = currency == DisplayCurrency.usd ? r'$' : '€';
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      name: name,
      symbol: symbol,
    );
    return formatter.format(value);
  }

  static String formatCompactCurrency(num value, String locale) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      name: 'EUR',
      symbol: '€',
    );
    return formatter.format(value);
  }

  static String formatCompactNumber(num value, String locale) {
    final formatter = NumberFormat.compact(locale: locale);
    return formatter.format(value);
  }

  static String formatStatValue(num value, String locale) {
    if (value.abs() >= 1e9) {
      return formatCompactCurrency(value, locale);
    }
    if (value.abs() >= 1e6) {
      return formatCompactCurrency(value, locale);
    }
    return formatEurPrice(value, locale);
  }
}
