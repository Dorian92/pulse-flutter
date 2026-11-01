import 'package:flutter/material.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/app_theme.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';
import 'package:pulse/core/widgets/coin_list_tile.dart';
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/core/widgets/live_indicator.dart';
import 'package:pulse/core/widgets/market_summary_card.dart';
import 'package:pulse/core/widgets/no_live_feed_badge.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/core/widgets/price_change_pill.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/core/widgets/sparkline.dart';
import 'package:pulse/core/widgets/stats_grid.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Debug-only showcase of design system widgets.
class DesignGalleryPage extends StatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  var _useDark = true;
  MarketFilter _filter = MarketFilter.all;
  ChartPeriod _period = ChartPeriod.oneDay;
  var _flash = false;

  static const _sparkUp = [1.0, 1.2, 1.1, 1.4, 1.3, 1.6, 1.8];
  static const _sparkDown = [2.0, 1.9, 2.1, 1.7, 1.5, 1.4, 1.2];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AnimatedTheme(
      data: _useDark ? AppTheme.dark() : AppTheme.light(),
      duration: PulseTokens.standard.durationFast,
      child: Builder(
        builder: (context) {
          final tokens = context.pulseTokens;
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.designGalleryTitle),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _useDark = !_useDark),
                  child: Text(l10n.designGalleryThemeToggle),
                ),
              ],
            ),
            body: ListView(
              padding: EdgeInsets.all(tokens.spacingMd),
              children: [
                Text(
                  l10n.designGallerySectionComponents,
                  style: PulseTextStyles.screenTitle(context),
                ),
                SizedBox(height: tokens.spacingMd),
                const LiveIndicator(),
                SizedBox(height: tokens.spacingSm),
                const OfflineBanner(minutesAgo: 5),
                SizedBox(height: tokens.spacingMd),
                FilterChipsRow(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                SizedBox(height: tokens.spacingMd),
                MarketSummaryCard(
                  marketCapText: PulseFormatters.formatCompactCurrency(
                    2.31e12,
                    locale,
                  ),
                  changePercent: 1.8,
                ),
                SizedBox(height: tokens.spacingMd),
                PeriodSelector(
                  selected: _period,
                  onSelected: (value) => setState(() => _period = value),
                ),
                SizedBox(height: tokens.spacingMd),
                Row(
                  children: [
                    const PriceChangePill(changePercent: 2.41),
                    SizedBox(width: tokens.spacingSm),
                    const PriceChangePill(changePercent: -1.2),
                  ],
                ),
                SizedBox(height: tokens.spacingMd),
                const SizedBox(height: 48, child: Sparkline(values: _sparkUp)),
                SizedBox(height: tokens.spacingSm),
                const SizedBox(
                  height: 48,
                  child: Sparkline(values: _sparkDown),
                ),
                SizedBox(height: tokens.spacingMd),
                const NoLiveFeedBadge(),
                SizedBox(height: tokens.spacingMd),
                CoinListTile(
                  name: 'Bitcoin',
                  symbol: 'btc',
                  priceText: PulseFormatters.formatEurPrice(61284.12, locale),
                  changePercent: 2.41,
                  sparklineValues: _sparkUp,
                  showLiveFlash: _flash,
                ),
                SizedBox(height: tokens.spacingSm),
                TextButton(
                  onPressed: () => setState(() => _flash = true),
                  child: Text(l10n.designGalleryTriggerFlash),
                ),
                SizedBox(height: tokens.spacingSm),
                CoinListTile(
                  name: 'Chainlink',
                  symbol: 'link',
                  priceText: PulseFormatters.formatEurPrice(14.52, locale),
                  changePercent: -0.8,
                  sparklineValues: _sparkDown,
                  showNoLiveFeedBadge: true,
                ),
                SizedBox(height: tokens.spacingMd),
                StatsGrid(
                  items: [
                    StatTileData(
                      label: l10n.statMarketCap,
                      value: PulseFormatters.formatCompactCurrency(
                        1.2e12,
                        locale,
                      ),
                    ),
                    StatTileData(
                      label: l10n.statVolume24h,
                      value: PulseFormatters.formatCompactCurrency(
                        28e9,
                        locale,
                      ),
                    ),
                    StatTileData(
                      label: l10n.statHigh24h,
                      value: PulseFormatters.formatEurPrice(62000, locale),
                    ),
                    StatTileData(
                      label: l10n.statLow24h,
                      value: PulseFormatters.formatEurPrice(59800, locale),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacingMd),
                const ShimmerSkeleton(),
                SizedBox(height: tokens.spacingSm),
                const ShimmerSkeleton(variant: ShimmerVariant.detailHeader),
                SizedBox(height: tokens.spacingMd),
                Text(
                  l10n.designGalleryChartDeferred,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: tokens.spacingMd),
                Text(l10n.watchlistEmptyHint),
                SizedBox(height: tokens.spacingSm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.watchlistEdit,
                    style: TextStyle(color: context.pulseColors.accent),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
