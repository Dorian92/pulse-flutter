import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';
import 'package:pulse/core/widgets/price_change_pill.dart';
import 'package:pulse/l10n/app_localizations.dart';

class MarketSummaryCard extends StatelessWidget {
  const MarketSummaryCard({
    required this.marketCapText,
    required this.changePercent,
    super.key,
  });

  final String marketCapText;
  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Row(
          children: [
            Icon(
              Icons.stacked_line_chart,
              color: context.pulseColors.textSecondary,
            ),
            SizedBox(width: tokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.globalMarketCapLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    marketCapText,
                    style: PulseTextStyles.statValue(context),
                  ),
                ],
              ),
            ),
            PriceChangePill(changePercent: changePercent, showArrow: false),
          ],
        ),
      ),
    );
  }
}
