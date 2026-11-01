part of 'coin_detail_bloc.dart';

enum CoinDetailStatus { initial, loading, loaded, failure }

class CoinDetailState extends Equatable {
  const CoinDetailState({
    required this.status,
    required this.coinId,
    this.detail,
    this.chart,
    this.selectedRange = ChartPeriod.oneDay,
    this.livePriceEur,
    this.changePercent24h,
    this.realtimeStatus = const RealtimeStatus.offline(),
    this.isStale = false,
    this.chartLoading = false,
    this.chartFailure,
    this.failure,
    this.isWatchlisted = false,
    this.fetchedAt,
  });

  const CoinDetailState.initial()
    : this(status: CoinDetailStatus.initial, coinId: '');

  factory CoinDetailState.loading({
    required String coinId,
    ChartPeriod selectedRange = ChartPeriod.oneDay,
  }) {
    return CoinDetailState(
      status: CoinDetailStatus.loading,
      coinId: coinId,
      selectedRange: selectedRange,
      chartLoading: true,
    );
  }

  factory CoinDetailState.loaded({
    required String coinId,
    required CoinDetail detail,
    required ChartPeriod selectedRange,
    required double livePriceEur,
    required double changePercent24h,
    required RealtimeStatus realtimeStatus,
    required bool isStale,
    required bool chartLoading,
    required bool isWatchlisted,
    PriceChartSeries? chart,
    AppFailure? chartFailure,
    DateTime? fetchedAt,
  }) {
    return CoinDetailState(
      status: CoinDetailStatus.loaded,
      coinId: coinId,
      detail: detail,
      chart: chart,
      selectedRange: selectedRange,
      livePriceEur: livePriceEur,
      changePercent24h: changePercent24h,
      realtimeStatus: realtimeStatus,
      isStale: isStale,
      chartLoading: chartLoading,
      chartFailure: chartFailure,
      isWatchlisted: isWatchlisted,
      fetchedAt: fetchedAt ?? detail.fetchedAt,
    );
  }

  factory CoinDetailState.failure({
    required String coinId,
    required AppFailure failure,
  }) {
    return CoinDetailState(
      status: CoinDetailStatus.failure,
      coinId: coinId,
      failure: failure,
    );
  }

  final CoinDetailStatus status;
  final String coinId;
  final CoinDetail? detail;
  final PriceChartSeries? chart;
  final ChartPeriod selectedRange;
  final double? livePriceEur;
  final double? changePercent24h;
  final RealtimeStatus realtimeStatus;
  final bool isStale;
  final bool chartLoading;
  final AppFailure? chartFailure;
  final AppFailure? failure;
  final bool isWatchlisted;
  final DateTime? fetchedAt;

  bool get showLiveIndicator =>
      detail?.hasLiveFeed == true && realtimeStatus.isLiveIndicatorActive;

  CoinDetailState copyWith({
    CoinDetailStatus? status,
    String? coinId,
    CoinDetail? detail,
    PriceChartSeries? chart,
    ChartPeriod? selectedRange,
    double? livePriceEur,
    double? changePercent24h,
    RealtimeStatus? realtimeStatus,
    bool? isStale,
    bool? chartLoading,
    AppFailure? chartFailure,
    bool clearChartFailure = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isWatchlisted,
    DateTime? fetchedAt,
  }) {
    return CoinDetailState(
      status: status ?? this.status,
      coinId: coinId ?? this.coinId,
      detail: detail ?? this.detail,
      chart: chart ?? this.chart,
      selectedRange: selectedRange ?? this.selectedRange,
      livePriceEur: livePriceEur ?? this.livePriceEur,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      isStale: isStale ?? this.isStale,
      chartLoading: chartLoading ?? this.chartLoading,
      chartFailure: clearChartFailure
          ? null
          : chartFailure ?? this.chartFailure,
      failure: clearFailure ? null : failure ?? this.failure,
      isWatchlisted: isWatchlisted ?? this.isWatchlisted,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    coinId,
    detail,
    chart,
    selectedRange,
    livePriceEur,
    changePercent24h,
    realtimeStatus,
    isStale,
    chartLoading,
    chartFailure,
    failure,
    isWatchlisted,
    fetchedAt,
  ];
}
