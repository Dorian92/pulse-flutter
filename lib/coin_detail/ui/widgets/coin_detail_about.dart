import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// About section with plain description text and optional homepage URL.
class CoinDetailAbout extends StatelessWidget {
  const CoinDetailAbout({required this.text, this.homepageUrl, super.key});

  final String text;
  final String? homepageUrl;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty && (homepageUrl == null || homepageUrl!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;
    final colors = context.pulseColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coinDetailAboutTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (text.isNotEmpty) ...[
          SizedBox(height: tokens.spacingSm),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (homepageUrl != null && homepageUrl!.isNotEmpty) ...[
          SizedBox(height: tokens.spacingMd),
          Text(
            l10n.coinDetailHomepageLabel,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: tokens.spacingXs),
          SelectableText(
            homepageUrl!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.accent),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: homepageUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.coinDetailHomepageCopied)),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: Text(l10n.coinDetailHomepageCopy),
          ),
        ],
      ],
    );
  }
}
