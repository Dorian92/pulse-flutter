import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Green dot and LIVE label for connected streams.
class LiveIndicator extends StatelessWidget {
  const LiveIndicator({this.active = true, super.key});

  /// When false, shows a muted placeholder until live streams connect (step 5).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;
    final dotColor = active ? colors.positive : colors.textMuted;
    final labelColor = active ? colors.positive : colors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: tokens.spacingXs),
        Text(
          l10n.liveIndicatorLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
