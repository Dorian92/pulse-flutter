import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed);
    return _baseTheme(colorScheme, PulseColors.light);
  }

  static ThemeData dark() {
    const seed = Color(0xFF60A5FA);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _baseTheme(colorScheme, PulseColors.dark);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme, PulseColors pulse) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[
        PulseColors.light,
        PulseTokens.standard,
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: pulse.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseTokens.standard.radiusMd),
        ),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[pulse, PulseTokens.standard],
    );
  }
}
