import 'package:flutter/material.dart';
import 'package:pulse/core/formatting/pulse_formatters.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/core/theme/pulse_text_styles.dart';

/// Filled gain/loss percent pill used app-wide.
class PriceChangePill extends StatelessWidget {
  const PriceChangePill({
    required this.changePercent,
    this.showArrow = true,
    super.key,
  });

  final double changePercent;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final isGain = changePercent >= 0;
    final bg = isGain ? colors.positive : colors.negative;
    final arrow = isGain ? '▲' : '▼';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = PulseFormatters.formatPercentChange(
      changePercent,
      locale,
    );
    final label = showArrow ? '$arrow $formatted' : formatted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PulseTextStyles.percent(context, color: Colors.white),
      ),
    );
  }
}
