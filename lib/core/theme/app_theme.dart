import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const pulse = PulseColors.light;
    final colorScheme = ColorScheme.light(
      primary: pulse.accent,
      onPrimary: pulse.onAccent,
      secondary: pulse.accent,
      onSecondary: pulse.onAccent,
      surface: pulse.surfaceElevated,
      onSurface: const Color(0xFF0F172A),
      error: pulse.negative,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      pulse: pulse,
      scaffoldBackground: const Color(0xFFF8FAFC),
    );
  }

  static ThemeData dark() {
    const pulse = PulseColors.dark;
    final colorScheme = ColorScheme.dark(
      primary: pulse.accent,
      onPrimary: pulse.onAccent,
      secondary: pulse.accent,
      onSecondary: pulse.onAccent,
      surface: pulse.surfaceElevated,
      onSurface: const Color(0xFFF1F5F9),
      error: pulse.negative,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      pulse: pulse,
      scaffoldBackground: const Color(0xFF0B0E14),
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required PulseColors pulse,
    required Color scaffoldBackground,
  }) {
    const tokens = PulseTokens.standard;
    final textTheme = _textTheme(colorScheme, pulse);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: pulse.accent.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: pulse.surfaceElevated,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: pulse.accent);
          }
          return IconThemeData(color: pulse.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium!;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: pulse.accent);
          }
          return base.copyWith(color: pulse.textSecondary);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: pulse.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: pulse.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: pulse.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pulse.chipUnselectedFill,
        selectedColor: pulse.accent,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: pulse.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
    ).copyWith(extensions: <ThemeExtension<dynamic>>[pulse, tokens]);
  }

  static TextTheme _textTheme(ColorScheme colorScheme, PulseColors pulse) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: pulse.textSecondary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    );
  }
}
