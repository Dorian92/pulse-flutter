import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';
import 'package:pulse/core/widgets/no_live_feed_badge.dart';
import 'package:pulse/core/widgets/price_change_pill.dart';
import 'package:pulse/core/widgets/sparkline.dart';

/// Presentational market/watchlist row for a single coin.
class CoinListTile extends StatefulWidget {
  const CoinListTile({
    required this.name,
    required this.symbol,
    required this.priceText,
    required this.changePercent,
    required this.sparklineValues,
    this.icon,
    this.compactSparkline = false,
    this.showLiveFlash = false,
    this.liveFlashToken,
    this.showNoLiveFeedBadge = false,
    this.onTap,
    super.key,
  });

  final String name;
  final String symbol;
  final String priceText;
  final double changePercent;
  final List<double> sparklineValues;
  final Widget? icon;
  final bool compactSparkline;
  final bool showLiveFlash;
  final int? liveFlashToken;
  final bool showNoLiveFeedBadge;
  final VoidCallback? onTap;

  @override
  State<CoinListTile> createState() => _CoinListTileState();
}

class _CoinListTileState extends State<CoinListTile> {
  bool _flashVisible = false;

  @override
  void initState() {
    super.initState();
    _flashVisible = widget.showLiveFlash;
  }

  @override
  void didUpdateWidget(CoinListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liveFlashToken != null &&
        widget.liveFlashToken != oldWidget.liveFlashToken) {
      setState(() => _flashVisible = true);
      Future<void>.delayed(PulseTokens.standard.durationMedium, () {
        if (mounted) {
          setState(() => _flashVisible = false);
        }
      });
    } else if (widget.showLiveFlash && !oldWidget.showLiveFlash) {
      setState(() => _flashVisible = true);
      Future<void>.delayed(PulseTokens.standard.durationMedium, () {
        if (mounted) {
          setState(() => _flashVisible = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    final colors = context.pulseColors;
    final height = widget.compactSparkline
        ? tokens.listTileHeight
        : tokens.watchlistTileHeight;
    final sparklineWidth = widget.compactSparkline ? 56.0 : 72.0;

    return AnimatedContainer(
      duration: tokens.durationMedium,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: _flashVisible ? colors.liveFlashBorder : colors.borderSubtle,
        ),
      ),
      child: Material(
        color: _flashVisible ? colors.liveFlashFill : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
              child: Row(
                children: [
                  widget.icon ??
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.chipUnselectedFill,
                        child: Text(
                          widget.symbol.characters.first,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (widget.showNoLiveFeedBadge)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: NoLiveFeedBadge(compact: true),
                              ),
                          ],
                        ),
                        Text(
                          widget.symbol.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: sparklineWidth,
                    height: 32,
                    child: Sparkline(values: widget.sparklineValues),
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.priceText,
                        style: PulseTextStyles.price(context),
                      ),
                      SizedBox(height: tokens.spacingXs),
                      PriceChangePill(changePercent: widget.changePercent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
