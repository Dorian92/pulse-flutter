import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Amber banner when prices are stale / offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.minutesAgo, super.key});

  final int minutesAgo;

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colors.stale.withValues(alpha: 0.15),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingMd,
          vertical: tokens.spacingSm,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.stale, size: 20),
            SizedBox(width: tokens.spacingSm),
            Expanded(
              child: Text(
                l10n.offlineBannerMessage(minutesAgo),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.stale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
