import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/widgets/coin_list_tile.dart';
import 'package:pulse/core/widgets/filter_chips_row.dart';
import 'package:pulse/core/widgets/live_indicator.dart';
import 'package:pulse/core/widgets/market_summary_card.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/bloc/markets_bloc.dart';
import 'package:pulse/markets/repository/markets_repository.dart';

/// Top coins list (REST + cache); live prices arrive in step 5.
class MarketsPage extends StatelessWidget {
  /// Creates the markets screen.
  ///
  /// [bloc] is for tests; production uses [MarketsBloc] from DI.
  const MarketsPage({this.bloc, super.key});

  /// Optional pre-built bloc (widget tests).
  final MarketsBloc? bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final marketsBloc =
            bloc ??
            MarketsBloc(
              repository: sl<MarketsRepository>(),
              subscriptionCoordinator: sl<RealtimeSubscriptionCoordinator>(),
              priceStreamService: sl<PriceStreamService>(),
            );
        if (bloc == null) {
          marketsBloc.add(const MarketsRequested());
        }
        return marketsBloc;
      },
      child: const _MarketsView(),
    );
  }
}

class _MarketsView extends StatefulWidget {
  const _MarketsView();

  @override
  State<_MarketsView> createState() => _MarketsViewState();
}

class _MarketsViewState extends State<_MarketsView> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;

    return BlocConsumer<MarketsBloc, MarketsState>(
      listenWhen: (previous, current) =>
          current.refreshFailure != null &&
          current.refreshFailure != previous.refreshFailure,
      listener: (context, state) {
        final failure = state.refreshFailure;
        if (failure == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message(l10n))));
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacingMd,
                    tokens.spacingSm,
                    tokens.spacingMd,
                    tokens.spacingSm,
                  ),
                  child: _MarketsHeader(
                    searchOpen: _searchOpen,
                    searchController: _searchController,
                    liveActive: state.realtimeStatus.isLiveIndicatorActive,
                    onToggleSearch: () {
                      setState(() => _searchOpen = !_searchOpen);
                    },
                    onSearchChanged: (query) {
                      context.read<MarketsBloc>().add(
                        MarketsSearchQueryChanged(query),
                      );
                    },
                  ),
                ),
                if (state.isStale && state.fetchedAt != null)
                  OfflineBanner(minutesAgo: _minutesSince(state.fetchedAt!)),
                Expanded(child: _buildBody(context, state, l10n)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MarketsState state,
    AppLocalizations l10n,
  ) {
    final tokens = context.pulseTokens;

    if (state.status == MarketsStatus.loading && state.snapshot == null) {
      return ListView.separated(
        padding: EdgeInsets.all(tokens.spacingMd),
        itemCount: 8,
        separatorBuilder: (_, __) => SizedBox(height: tokens.spacingSm),
        itemBuilder: (_, __) => const ShimmerSkeleton(),
      );
    }

    if (state.status == MarketsStatus.failure && state.snapshot == null) {
      final failure = state.failure;
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                failure?.message(l10n) ?? l10n.errorUnknown,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingMd),
              FilledButton(
                onPressed: () {
                  context.read<MarketsBloc>().add(const MarketsRequested());
                },
                child: Text(l10n.marketsRetry),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context).toString();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MarketsBloc>().add(const MarketsRefreshRequested());
        await context.read<MarketsBloc>().stream.firstWhere(
          (s) => s.status != MarketsStatus.loading,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilterChipsRow(
                    selected: state.filter,
                    includeWatchlistChip: false,
                    onSelected: (filter) {
                      context.read<MarketsBloc>().add(
                        MarketsFilterChanged(filter),
                      );
                    },
                  ),
                  SizedBox(height: tokens.spacingMd),
                  if (snapshot.global.hasMarketCap)
                    MarketSummaryCard(
                      marketCapText: PulseFormatters.formatCompactCurrency(
                        snapshot.global.totalMarketCapEur!,
                        locale,
                      ),
                      changePercent: snapshot.global.marketCapChangePercent24h,
                    ),
                  if (snapshot.global.hasMarketCap)
                    SizedBox(height: tokens.spacingMd),
                ],
              ),
            ),
          ),
          if (state.visibleCoins.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacingLg),
                  child: Text(
                    state.searchQuery.isNotEmpty
                        ? l10n.marketsNoSearchResults
                        : l10n.marketsEmptyFilter,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacingMd,
                0,
                tokens.spacingMd,
                tokens.spacingLg,
              ),
              sliver: SliverList.separated(
                itemCount: state.visibleCoins.length,
                separatorBuilder: (_, __) => SizedBox(height: tokens.spacingSm),
                itemBuilder: (context, index) {
                  final coin = state.visibleCoins[index];
                  return CoinListTile(
                    compactSparkline: true,
                    name: coin.name,
                    symbol: coin.symbol,
                    priceText: PulseFormatters.formatEurPrice(
                      coin.currentPriceEur,
                      locale,
                    ),
                    changePercent: coin.priceChangePercent24h,
                    sparklineValues: coin.sparkline7d,
                    showNoLiveFeedBadge: !coin.hasLiveFeed,
                    liveFlashToken: coin.id == state.liveFlashCoinId
                        ? state.liveFlashGeneration
                        : null,
                    icon: coin.imageUrl.isEmpty
                        ? null
                        : CircleAvatar(
                            backgroundImage: NetworkImage(coin.imageUrl),
                            backgroundColor:
                                context.pulseColors.chipUnselectedFill,
                          ),
                    onTap: () =>
                        context.push(AppRoutes.coinDetailPath(coin.id)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  int _minutesSince(DateTime fetchedAt) {
    final diff = DateTime.now().toUtc().difference(fetchedAt.toUtc());
    return diff.inMinutes.clamp(0, 9999);
  }
}

class _MarketsHeader extends StatelessWidget {
  const _MarketsHeader({
    required this.searchOpen,
    required this.searchController,
    required this.liveActive,
    required this.onToggleSearch,
    required this.onSearchChanged,
  });

  final bool searchOpen;
  final TextEditingController searchController;
  final bool liveActive;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;

    if (searchOpen) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.marketsSearchHint,
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          IconButton(onPressed: onToggleSearch, icon: const Icon(Icons.close)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.tabMarkets,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        LiveIndicator(active: liveActive),
        SizedBox(width: tokens.spacingSm),
        IconButton(onPressed: onToggleSearch, icon: const Icon(Icons.search)),
      ],
    );
  }
}
