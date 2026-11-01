import 'package:flutter/material.dart';

/// Semantic color roles for Pulse UI. Access via [Theme.of(context).extension].
@immutable
class PulseColors extends ThemeExtension<PulseColors> {
  const PulseColors({
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.stale,
    required this.noLiveFeed,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.accent,
    required this.liveFlashFill,
    required this.liveFlashBorder,
    required this.textSecondary,
    required this.textMuted,
    required this.onAccent,
    required this.chipUnselectedFill,
  });

  final Color positive;
  final Color negative;
  final Color neutral;
  final Color stale;
  final Color noLiveFeed;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color accent;
  final Color liveFlashFill;
  final Color liveFlashBorder;
  final Color textSecondary;
  final Color textMuted;
  final Color onAccent;
  final Color chipUnselectedFill;

  static const PulseColors light = PulseColors(
    positive: Color(0xFF0E9F6E),
    negative: Color(0xFFDC2626),
    neutral: Color(0xFF64748B),
    stale: Color(0xFFD97706),
    noLiveFeed: Color(0xFF94A3B8),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE2E8F0),
    accent: Color(0xFF6D4FE0),
    liveFlashFill: Color(0x1F0E9F6E),
    liveFlashBorder: Color(0x400E9F6E),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    onAccent: Color(0xFFFFFFFF),
    chipUnselectedFill: Color(0xFFF1F5F9),
  );

  static const PulseColors dark = PulseColors(
    positive: Color(0xFF16C784),
    negative: Color(0xFFEA3943),
    neutral: Color(0xFF94A3B8),
    stale: Color(0xFFF59E0B),
    noLiveFeed: Color(0xFF475569),
    surfaceElevated: Color(0xFF131722),
    borderSubtle: Color(0xFF1E2230),
    accent: Color(0xFF7C5CFF),
    liveFlashFill: Color(0x1F16C784),
    liveFlashBorder: Color(0x4016C784),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    onAccent: Color(0xFFFFFFFF),
    chipUnselectedFill: Color(0xFF1E2230),
  );

  @override
  PulseColors copyWith({
    Color? positive,
    Color? negative,
    Color? neutral,
    Color? stale,
    Color? noLiveFeed,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? accent,
    Color? liveFlashFill,
    Color? liveFlashBorder,
    Color? textSecondary,
    Color? textMuted,
    Color? onAccent,
    Color? chipUnselectedFill,
  }) {
    return PulseColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      neutral: neutral ?? this.neutral,
      stale: stale ?? this.stale,
      noLiveFeed: noLiveFeed ?? this.noLiveFeed,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accent: accent ?? this.accent,
      liveFlashFill: liveFlashFill ?? this.liveFlashFill,
      liveFlashBorder: liveFlashBorder ?? this.liveFlashBorder,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onAccent: onAccent ?? this.onAccent,
      chipUnselectedFill: chipUnselectedFill ?? this.chipUnselectedFill,
    );
  }

  @override
  PulseColors lerp(ThemeExtension<PulseColors>? other, double t) {
    if (other is! PulseColors) {
      return this;
    }
    return PulseColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      stale: Color.lerp(stale, other.stale, t)!,
      noLiveFeed: Color.lerp(noLiveFeed, other.noLiveFeed, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      liveFlashFill: Color.lerp(liveFlashFill, other.liveFlashFill, t)!,
      liveFlashBorder: Color.lerp(liveFlashBorder, other.liveFlashBorder, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      chipUnselectedFill: Color.lerp(
        chipUnselectedFill,
        other.chipUnselectedFill,
        t,
      )!,
    );
  }
}

/// Spacing, radius, and motion tokens.
@immutable
class PulseTokens extends ThemeExtension<PulseTokens> {
  const PulseTokens({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.listTileHeight,
    required this.watchlistTileHeight,
    required this.durationFast,
    required this.durationMedium,
    required this.durationSlow,
  });

  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double listTileHeight;
  final double watchlistTileHeight;
  final Duration durationFast;
  final Duration durationMedium;
  final Duration durationSlow;

  static const PulseTokens standard = PulseTokens(
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 16,
    spacingLg: 24,
    spacingXl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    listTileHeight: 72,
    watchlistTileHeight: 80,
    durationFast: Duration(milliseconds: 150),
    durationMedium: Duration(milliseconds: 300),
    durationSlow: Duration(milliseconds: 450),
  );

  @override
  PulseTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? listTileHeight,
    double? watchlistTileHeight,
    Duration? durationFast,
    Duration? durationMedium,
    Duration? durationSlow,
  }) {
    return PulseTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      listTileHeight: listTileHeight ?? this.listTileHeight,
      watchlistTileHeight: watchlistTileHeight ?? this.watchlistTileHeight,
      durationFast: durationFast ?? this.durationFast,
      durationMedium: durationMedium ?? this.durationMedium,
      durationSlow: durationSlow ?? this.durationSlow,
    );
  }

  @override
  PulseTokens lerp(ThemeExtension<PulseTokens>? other, double t) {
    if (other is! PulseTokens) {
      return this;
    }
    return PulseTokens(
      spacingXs: spacingXs + (other.spacingXs - spacingXs) * t,
      spacingSm: spacingSm + (other.spacingSm - spacingSm) * t,
      spacingMd: spacingMd + (other.spacingMd - spacingMd) * t,
      spacingLg: spacingLg + (other.spacingLg - spacingLg) * t,
      spacingXl: spacingXl + (other.spacingXl - spacingXl) * t,
      radiusSm: radiusSm + (other.radiusSm - radiusSm) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      radiusLg: radiusLg + (other.radiusLg - radiusLg) * t,
      listTileHeight:
          listTileHeight + (other.listTileHeight - listTileHeight) * t,
      watchlistTileHeight:
          watchlistTileHeight +
          (other.watchlistTileHeight - watchlistTileHeight) * t,
      durationFast: Duration(
        milliseconds:
            (durationFast.inMilliseconds +
                    (other.durationFast.inMilliseconds -
                            durationFast.inMilliseconds) *
                        t)
                .round(),
      ),
      durationMedium: Duration(
        milliseconds:
            (durationMedium.inMilliseconds +
                    (other.durationMedium.inMilliseconds -
                            durationMedium.inMilliseconds) *
                        t)
                .round(),
      ),
      durationSlow: Duration(
        milliseconds:
            (durationSlow.inMilliseconds +
                    (other.durationSlow.inMilliseconds -
                            durationSlow.inMilliseconds) *
                        t)
                .round(),
      ),
    );
  }
}

extension PulseThemeContext on BuildContext {
  PulseColors get pulseColors =>
      Theme.of(this).extension<PulseColors>() ?? PulseColors.light;

  PulseTokens get pulseTokens =>
      Theme.of(this).extension<PulseTokens>() ?? PulseTokens.standard;
}
