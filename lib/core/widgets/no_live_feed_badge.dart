import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Gray badge when a symbol has no Binance live feed.
class NoLiveFeedBadge extends StatelessWidget {
  const NoLiveFeedBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final l10n = AppLocalizations.of(context)!;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.noLiveFeed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l10n.noLiveFeedBadge,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.noLiveFeed,
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }
}
