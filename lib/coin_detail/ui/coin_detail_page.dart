import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

class CoinDetailPage extends StatelessWidget {
  const CoinDetailPage({required this.coinId, super.key});

  final String coinId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.pulseTokens;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coinDetailPlaceholderTitle)),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingMd),
            child: Text(
              l10n.coinDetailPlaceholderBody(coinId),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
