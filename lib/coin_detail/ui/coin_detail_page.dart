import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/coin_detail/bloc/coin_detail_bloc.dart';
import 'package:pulse/coin_detail/repository/coin_detail_repository.dart';
import 'package:pulse/coin_detail/ui/widgets/coin_detail_about.dart';
import 'package:pulse/coin_detail/ui/widgets/coin_detail_header.dart';
import 'package:pulse/coin_detail/ui/widgets/price_chart.dart';
import 'package:pulse/coin_detail/watchlist/watchlist_toggle.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/realtime/price_stream_service.dart';
import 'package:pulse/core/realtime/realtime_subscription_coordinator.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/widgets/offline_banner.dart';
import 'package:pulse/core/widgets/period_selector.dart';
import 'package:pulse/core/widgets/shimmer_skeleton.dart';
import 'package:pulse/core/widgets/stats_grid.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Coin detail screen with chart, stats, and live price.
class CoinDetailPage extends StatelessWidget {
  const CoinDetailPage({required this.coinId, this.bloc, super.key});

  final String coinId;
  final CoinDetailBloc? bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final detailBloc =
            bloc ??
            CoinDetailBloc(
              repository: sl<CoinDetailRepository>(),
              subscriptionCoordinator: sl<RealtimeSubscriptionCoordinator>(),
              priceStreamService: sl<PriceStreamService>(),
              watchlistToggle: sl<WatchlistToggle>(),
            );
        if (bloc == null) {
          detailBloc.add(CoinDetailStarted(coinId));
        }
        return detailBloc;
      },
      child: _CoinDetailView(coinId: coinId),
    );
  }
}

class _CoinDetailView extends StatelessWidget {
  const _CoinDetailView({required this.coinId});

  final String coinId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CoinDetailBloc, CoinDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: Text(state.detail?.name ?? coinId),
          ),
          body: switch (state.status) {
            CoinDetailStatus.initial ||
            CoinDetailStatus.loading => _LoadingBody(),
            CoinDetailStatus.failure => _ErrorBody(
              message: state.failure?.message(l10n) ?? l10n.errorUnknown,
              onRetry: () => context.read<CoinDetailBloc>().add(
                const CoinDetailRetryRequested(),
              ),
            ),
            CoinDetailStatus.loaded => _LoadedBody(state: state),
          },
        );
      },
    );
  }
}

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    return ListView(
      padding: EdgeInsets.all(tokens.spacingMd),
      children: const [
        ShimmerSkeleton(variant: ShimmerVariant.detailHeader),
        SizedBox(height: 16),
        ShimmerSkeleton(variant: ShimmerVariant.detailHeader),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: tokens.spacingMd),
            FilledButton(onPressed: onRetry, child: Text(l10n.marketsRetry)),
          ],
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final CoinDetailState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final tokens = context.pulseTokens;
    final minutesAgo = state.fetchedAt != null
        ? DateTime.now()
              .toUtc()
              .difference(state.fetchedAt!)
              .inMinutes
              .clamp(1, 9999)
        : 1;

    return ListView(
      padding: EdgeInsets.all(tokens.spacingMd),
      children: [
        if (state.isStale) OfflineBanner(minutesAgo: minutesAgo),
        CoinDetailHeader(
          detail: detail,
          livePriceEur: state.livePriceEur ?? detail.currentPriceEur,
          changePercent24h:
              state.changePercent24h ?? detail.priceChangePercent24h,
          showLiveIndicator: state.showLiveIndicator,
          isWatchlisted: state.isWatchlisted,
          onWatchlistToggle: () => context.read<CoinDetailBloc>().add(
            const CoinDetailWatchlistToggled(),
          ),
        ),
        SizedBox(height: tokens.spacingLg),
        if (state.chartLoading)
          const ShimmerSkeleton(variant: ShimmerVariant.detailHeader)
        else if (state.chart != null && state.chart!.points.length >= 2)
          PriceChart(points: state.chart!.points, locale: locale)
        else if (state.chart != null && state.chart!.points.length < 2)
          _ChartEmpty(message: l10n.coinDetailChartEmpty)
        else if (state.chartFailure != null)
          _ChartError(
            message: l10n.coinDetailChartError,
            onRetry: () => context.read<CoinDetailBloc>().add(
              CoinDetailChartRangeChanged(state.selectedRange),
            ),
          ),
        SizedBox(height: tokens.spacingMd),
        PeriodSelector(
          selected: state.selectedRange,
          onSelected: (range) => context.read<CoinDetailBloc>().add(
            CoinDetailChartRangeChanged(range),
          ),
        ),
        SizedBox(height: tokens.spacingLg),
        StatsGrid(
          items: [
            StatTileData(
              label: l10n.statMarketCap,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.marketCapEur,
                compactCurrency: true,
              ),
            ),
            StatTileData(
              label: l10n.statVolume24h,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.volume24hEur,
                compactCurrency: true,
              ),
            ),
            StatTileData(
              label: l10n.statHigh24h,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.high24hEur,
              ),
            ),
            StatTileData(
              label: l10n.statLow24h,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.low24hEur,
              ),
            ),
            StatTileData(
              label: l10n.statCirculatingSupply,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.circulatingSupply,
                compactNumber: true,
              ),
            ),
            StatTileData(
              label: l10n.statAllTimeHigh,
              value: _formatStat(
                l10n: l10n,
                locale: locale,
                value: detail.athEur,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        CoinDetailAbout(
          text: detail.aboutTextEn,
          homepageUrl: detail.homepageUrl,
        ),
      ],
    );
  }
}

String _formatStat({
  required AppLocalizations l10n,
  required String locale,
  required double? value,
  bool compactCurrency = false,
  bool compactNumber = false,
}) {
  if (value == null) {
    return l10n.statUnknown;
  }
  if (compactNumber) {
    return PulseFormatters.formatCompactNumber(value, locale);
  }
  if (compactCurrency) {
    return PulseFormatters.formatCompactCurrency(value, locale);
  }
  return PulseFormatters.formatEurPrice(value, locale);
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.pulseTokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: tokens.spacingSm),
            TextButton(onPressed: onRetry, child: Text(l10n.marketsRetry)),
          ],
        ),
      ),
    );
  }
}
