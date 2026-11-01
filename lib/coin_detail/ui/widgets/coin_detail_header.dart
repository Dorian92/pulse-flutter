import 'package:flutter/material.dart';
import 'package:pulse/coin_detail/models/coin_detail.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';
import 'package:pulse/core/widgets/live_indicator.dart';
import 'package:pulse/core/widgets/no_live_feed_badge.dart';
import 'package:pulse/core/widgets/price_change_pill.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Hero header: icon, name, live price, change pill, live badge.
class CoinDetailHeader extends StatelessWidget {
  const CoinDetailHeader({
    required this.detail,
    required this.livePriceEur,
    required this.changePercent24h,
    required this.showLiveIndicator,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
    super.key,
  });

  final CoinDetail detail;
  final double livePriceEur;
  final double changePercent24h;
  final bool showLiveIndicator;
  final bool isWatchlisted;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final tokens = context.pulseTokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: detail.imageUrl.isNotEmpty
                  ? NetworkImage(detail.imageUrl)
                  : null,
              child: detail.imageUrl.isEmpty
                  ? Text(detail.symbol.characters.first)
                  : null,
            ),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail.symbol,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.pulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onWatchlistToggle,
              icon: Icon(
                isWatchlisted ? Icons.star : Icons.star_border,
                color: isWatchlisted
                    ? context.pulseColors.accent
                    : context.pulseColors.textSecondary,
              ),
              tooltip: isWatchlisted
                  ? l10n.coinDetailRemoveWatchlist
                  : l10n.coinDetailAddWatchlist,
            ),
          ],
        ),
        SizedBox(height: tokens.spacingMd),
        Text(
          PulseFormatters.formatEurPrice(livePriceEur, locale),
          style: PulseTextStyles.priceLarge(context),
        ),
        SizedBox(height: tokens.spacingSm),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PriceChangePill(changePercent: changePercent24h),
            if (detail.hasLiveFeed)
              LiveIndicator(active: showLiveIndicator)
            else
              const NoLiveFeedBadge(),
          ],
        ),
      ],
    );
  }
}
