import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';

enum MarketFilter { all, gainers, losers, watchlist }

extension MarketFilterX on MarketFilter {
  String label(AppLocalizations l10n) {
    switch (this) {
      case MarketFilter.all:
        return l10n.filterAll;
      case MarketFilter.gainers:
        return l10n.filterGainers;
      case MarketFilter.losers:
        return l10n.filterLosers;
      case MarketFilter.watchlist:
        return l10n.filterWatchlist;
    }
  }
}

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    required this.selected,
    required this.onSelected,
    this.includeWatchlistChip = true,
    super.key,
  });

  final MarketFilter selected;
  final ValueChanged<MarketFilter> onSelected;

  /// When false, hides the watchlist chip (markets screen until step 7).
  final bool includeWatchlistChip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    final l10n = AppLocalizations.of(context)!;
    final filters = includeWatchlistChip
        ? MarketFilter.values
        : MarketFilter.values
              .where((f) => f != MarketFilter.watchlist)
              .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _FilterChip(
              label: filter.label(l10n),
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
            if (filter != filters.last) SizedBox(width: tokens.spacingSm),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
