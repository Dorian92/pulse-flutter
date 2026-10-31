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
    required this.sparkline,
    required this.surfaceElevated,
  });

  final Color positive;
  final Color negative;
  final Color neutral;
  final Color stale;
  final Color noLiveFeed;
  final Color sparkline;
  final Color surfaceElevated;

  static const PulseColors light = PulseColors(
    positive: Color(0xFF0E9F6E),
    negative: Color(0xFFE02424),
    neutral: Color(0xFF6B7280),
    stale: Color(0xFFD97706),
    noLiveFeed: Color(0xFF9CA3AF),
    sparkline: Color(0xFF2563EB),
    surfaceElevated: Color(0xFFF3F4F6),
  );

  static const PulseColors dark = PulseColors(
    positive: Color(0xFF31C48D),
    negative: Color(0xFFF98080),
    neutral: Color(0xFF9CA3AF),
    stale: Color(0xFFFBBF24),
    noLiveFeed: Color(0xFF6B7280),
    sparkline: Color(0xFF60A5FA),
    surfaceElevated: Color(0xFF1F2937),
  );

  @override
  PulseColors copyWith({
    Color? positive,
    Color? negative,
    Color? neutral,
    Color? stale,
    Color? noLiveFeed,
    Color? sparkline,
    Color? surfaceElevated,
  }) {
    return PulseColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      neutral: neutral ?? this.neutral,
      stale: stale ?? this.stale,
      noLiveFeed: noLiveFeed ?? this.noLiveFeed,
      sparkline: sparkline ?? this.sparkline,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
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
      sparkline: Color.lerp(sparkline, other.sparkline, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
    );
  }
}

/// Spacing, radius, and typography scale tokens.
@immutable
class PulseTokens extends ThemeExtension<PulseTokens> {
  const PulseTokens({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.radiusSm,
    required this.radiusMd,
    required this.listTileHeight,
  });

  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double radiusSm;
  final double radiusMd;
  final double listTileHeight;

  static const PulseTokens standard = PulseTokens(
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 16,
    spacingLg: 24,
    radiusSm: 8,
    radiusMd: 12,
    listTileHeight: 72,
  );

  @override
  PulseTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? radiusSm,
    double? radiusMd,
    double? listTileHeight,
  }) {
    return PulseTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      listTileHeight: listTileHeight ?? this.listTileHeight,
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
      radiusSm: radiusSm + (other.radiusSm - radiusSm) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      listTileHeight:
          listTileHeight + (other.listTileHeight - listTileHeight) * t,
    );
  }
}

extension PulseThemeContext on BuildContext {
  PulseColors get pulseColors =>
      Theme.of(this).extension<PulseColors>() ?? PulseColors.light;

  PulseTokens get pulseTokens =>
      Theme.of(this).extension<PulseTokens>() ?? PulseTokens.standard;
}
