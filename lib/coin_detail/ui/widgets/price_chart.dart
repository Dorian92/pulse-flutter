import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/coin_detail/models/chart_point.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';

/// Interactive line chart with gradient fill and touch tooltip.
class PriceChart extends StatelessWidget {
  /// Creates a chart for [points].
  const PriceChart({required this.points, required this.locale, super.key});

  /// Samples oldest → newest.
  final List<ChartPoint> points;

  /// Locale for formatting.
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }

    final colors = context.pulseColors;
    final tokens = context.pulseTokens;
    final first = points.first.priceEur;
    final last = points.last.priceEur;
    final isUp = last >= first;
    final lineColor = isUp ? colors.positive : colors.negative;

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].priceEur),
    ];

    final minY = points.map((p) => p.priceEur).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.priceEur).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range.abs() < 1e-9
        ? (maxY.abs() * 0.005).clamp(1.0, double.infinity)
        : range * 0.08;
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (chartMaxY - chartMinY) / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: colors.borderSubtle, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  return Text(
                    PulseFormatters.formatCompactCurrency(value, locale),
                    style: PulseTextStyles.statLabel(context),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (points.length / 4)
                    .clamp(1, points.length)
                    .toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final ts = points[index].timestamp;
                  final label = DateFormat.Md(locale).format(ts.toLocal());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: PulseTextStyles.statLabel(context),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceElevated,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round().clamp(0, points.length - 1);
                  final point = points[index];
                  final timeLabel = DateFormat.yMMMd(
                    locale,
                  ).add_jm().format(point.timestamp.toLocal());
                  final priceLabel = PulseFormatters.formatEurPrice(
                    point.priceEur,
                    locale,
                  );
                  return LineTooltipItem(
                    '$priceLabel\n$timeLabel',
                    PulseTextStyles.price(context).copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: lineColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, i) =>
                        FlDotCirclePainter(radius: 4, color: lineColor),
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: tokens.durationMedium,
      ),
    );
  }
}
