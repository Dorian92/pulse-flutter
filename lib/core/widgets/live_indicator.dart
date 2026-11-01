import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Green dot and LIVE label for connected streams.
class LiveIndicator extends StatelessWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.positive,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: tokens.spacingXs),
        Text(
          l10n.liveIndicatorLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.positive,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
