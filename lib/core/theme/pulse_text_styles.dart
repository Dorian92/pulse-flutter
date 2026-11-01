import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';

/// Typography helpers with tabular figures for prices and stats.
abstract final class PulseTextStyles {
  static TextStyle price(BuildContext context, {Color? color, double? size}) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: size ?? 18,
      fontWeight: FontWeight.w600,
      color: color ?? theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle priceLarge(BuildContext context, {Color? color}) {
    return price(context, color: color, size: 32);
  }

  static TextStyle percent(BuildContext context, {Color? color, double? size}) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontSize: size ?? 12,
      fontWeight: FontWeight.w600,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle statValue(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle statLabel(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pulseColors;
    return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: colors.textSecondary,
    );
  }

  static TextStyle screenTitle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
  }
}
