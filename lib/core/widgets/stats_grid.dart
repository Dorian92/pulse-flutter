import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';

class StatTileData {
  const StatTileData({required this.label, required this.value});

  final String label;
  final String value;
}

/// Two-column stats grid with dividers (coin detail).
class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.items, super.key});

  final List<StatTileData> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - tokens.spacingMd) / 2;
            return Wrap(
              spacing: tokens.spacingMd,
              runSpacing: tokens.spacingMd,
              children: [
                for (var i = 0; i < items.length; i++)
                  SizedBox(
                    width: cellWidth,
                    child: StatTile(
                      label: items[i].label,
                      value: items[i].value,
                      showRightDivider:
                          i.isOdd == false && i < items.length - 1,
                      showBottomDivider: i < items.length - 2,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.showRightDivider = false,
    this.showBottomDivider = false,
    super.key,
  });

  final String label;
  final String value;
  final bool showRightDivider;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    final colors = context.pulseColors;

    return Container(
      padding: EdgeInsets.only(
        bottom: showBottomDivider ? tokens.spacingMd : 0,
        right: showRightDivider ? tokens.spacingMd : 0,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: showRightDivider
              ? BorderSide(color: colors.borderSubtle)
              : BorderSide.none,
          bottom: showBottomDivider
              ? BorderSide(color: colors.borderSubtle)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PulseTextStyles.statLabel(context)),
          SizedBox(height: tokens.spacingXs),
          Text(value, style: PulseTextStyles.statValue(context)),
        ],
      ),
    );
  }
}
