import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

enum ChartPeriod { oneDay, oneWeek, oneMonth, threeMonths, oneYear }

extension ChartPeriodX on ChartPeriod {
  String label(AppLocalizations l10n) {
    switch (this) {
      case ChartPeriod.oneDay:
        return l10n.periodOneDay;
      case ChartPeriod.oneWeek:
        return l10n.periodOneWeek;
      case ChartPeriod.oneMonth:
        return l10n.periodOneMonth;
      case ChartPeriod.threeMonths:
        return l10n.periodThreeMonths;
      case ChartPeriod.oneYear:
        return l10n.periodOneYear;
    }
  }
}

/// Period pills for coin detail (chart wiring in step 6).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  static const values = ChartPeriod.values;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in values) ...[
            _PeriodChip(
              label: period.label(l10n),
              selected: period == selected,
              onTap: () => onSelected(period),
            ),
            if (period != values.last) SizedBox(width: tokens.spacingSm),
          ],
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final tokens = context.pulseTokens;

    return Material(
      color: selected ? colors.accent : colors.chipUnselectedFill,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? colors.onAccent : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
