import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/realtime/symbol_mapper.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/widgets/coin_list_tile.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:pulse/settings/repository/settings_repository.dart';
import 'package:pulse/watchlist/bloc/watchlist_bloc.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';

/// Saved coins with live prices and reorder.
class WatchlistPage extends StatelessWidget {
  /// Creates the watchlist screen.
  const WatchlistPage({this.bloc, super.key});

  /// Optional bloc for tests.
  final WatchlistBloc? bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final watchlistBloc =
            bloc ??
            WatchlistBloc(
              repository: sl<WatchlistRepository>(),
              subscriptionCoordinator: sl<RealtimeSubscriptionCoordinator>(),
              priceStreamService: sl<PriceStreamService>(),
              symbolMapper: sl<SymbolMapper>(),
              settingsRepository: sl<SettingsRepository>(),
            );
        if (bloc == null) {
          watchlistBloc.add(const WatchlistRequested());
        }
        return watchlistBloc;
      },
      child: const _WatchlistView(),
    );
  }
}

class _WatchlistView extends StatelessWidget {
  const _WatchlistView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;
    final locale = Localizations.localeOf(context).toString();
    final currency = context
        .watch<SettingsCubit>()
        .state
        .preferences
        .displayCurrency;

    return BlocConsumer<WatchlistBloc, WatchlistState>(
      listenWhen: (previous, current) =>
          current.pendingUndo != null &&
          current.pendingUndo != previous.pendingUndo,
      listener: (context, state) {
        final undo = state.pendingUndo;
        if (undo == null) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.watchlistRemovedSnackbar(undo.coin.name)),
            action: SnackBarAction(
              label: l10n.watchlistUndo,
              onPressed: () {
                context.read<WatchlistBloc>().add(
                  const WatchlistUndoRemoveRequested(),
                );
              },
            ),
          ),
        );
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.tabWatchlist,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: state.coins.isEmpty
                            ? null
                            : () => context.read<WatchlistBloc>().add(
                                const WatchlistEditingToggled(),
                              ),
                        child: Text(
                          state.isEditing
                              ? l10n.watchlistDone
                              : l10n.watchlistEdit,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isStale && state.fetchedAt != null)
                  OfflineBanner(minutesAgo: _minutesSince(state.fetchedAt!)),
                Expanded(
                  child: _buildBody(context, state, l10n, locale, currency),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WatchlistState state,
    AppLocalizations l10n,
    String locale,
    DisplayCurrency currency,
  ) {
    final tokens = context.pulseTokens;

    if (state.status == WatchlistStatus.loading && state.coins.isEmpty) {
      return ListView.separated(
        padding: EdgeInsets.all(tokens.spacingMd),
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(height: tokens.spacingSm),
        itemBuilder: (_, __) => const ShimmerSkeleton(),
      );
    }

    if (state.status == WatchlistStatus.failure && state.coins.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.failure?.message(l10n) ?? l10n.errorUnknown,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingMd),
              FilledButton(
                onPressed: () {
                  context.read<WatchlistBloc>().add(const WatchlistRequested());
                },
                child: Text(l10n.marketsRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.coins.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.watchlistEmptyHint, textAlign: TextAlign.center),
              SizedBox(height: tokens.spacingMd),
              FilledButton(
                onPressed: () => context.go(AppRoutes.markets),
                child: Text(l10n.watchlistBrowseMarkets),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEditing) {
      return ReorderableListView.builder(
        padding: EdgeInsets.all(tokens.spacingMd),
        itemCount: state.coins.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          context.read<WatchlistBloc>().add(
            WatchlistReorderRequested(oldIndex: oldIndex, newIndex: newIndex),
          );
        },
        itemBuilder: (context, index) {
          final coin = state.coins[index];
          return _WatchlistTile(
            key: ValueKey(coin.id),
            coin: coin,
            locale: locale,
            currency: currency,
            liveFlashToken: coin.id == state.liveFlashCoinId
                ? state.liveFlashGeneration
                : null,
            dismissible: false,
            onTap: () => context.push(AppRoutes.coinDetailPath(coin.id)),
          );
        },
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(tokens.spacingMd),
      itemCount: state.coins.length,
      separatorBuilder: (_, __) => SizedBox(height: tokens.spacingSm),
      itemBuilder: (context, index) {
        final coin = state.coins[index];
        return _WatchlistTile(
          key: ValueKey(coin.id),
          coin: coin,
          locale: locale,
          currency: currency,
          liveFlashToken: coin.id == state.liveFlashCoinId
              ? state.liveFlashGeneration
              : null,
          dismissible: true,
          onDismissed: () {
            context.read<WatchlistBloc>().add(
              WatchlistRemoveRequested(coin.id),
            );
          },
          onTap: () => context.push(AppRoutes.coinDetailPath(coin.id)),
        );
      },
    );
  }

  int _minutesSince(DateTime fetchedAt) {
    final diff = DateTime.now().toUtc().difference(fetchedAt.toUtc());
    return diff.inMinutes.clamp(0, 9999);
  }
}

class _WatchlistTile extends StatelessWidget {
  const _WatchlistTile({
    required super.key,
    required this.coin,
    required this.locale,
    required this.currency,
    required this.liveFlashToken,
    required this.dismissible,
    required this.onTap,
    this.onDismissed,
  });

  final MarketCoin coin;
  final String locale;
  final DisplayCurrency currency;
  final int? liveFlashToken;
  final bool dismissible;
  final VoidCallback onTap;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tile = CoinListTile(
      compactSparkline: false,
      name: coin.name,
      symbol: coin.symbol,
      priceText: PulseFormatters.formatDisplayPrice(
        coin.currentPriceEur,
        locale,
        currency,
      ),
      changePercent: coin.priceChangePercent24h,
      sparklineValues: coin.sparkline7d,
      showNoLiveFeedBadge: !coin.hasLiveFeed,
      liveFlashToken: liveFlashToken,
      icon: coin.imageUrl.isEmpty
          ? null
          : CircleAvatar(
              backgroundImage: NetworkImage(coin.imageUrl),
              backgroundColor: context.pulseColors.chipUnselectedFill,
            ),
      onTap: onTap,
    );

    if (!dismissible || onDismissed == null) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('dismiss-${coin.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: Text(
          l10n.removeActionLabel,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      onDismissed: (_) => onDismissed!(),
      child: tile,
    );
  }
}
