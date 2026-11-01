import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';

enum ShimmerVariant { listTile, detailHeader }

/// Placeholder shimmer blocks for loading states.
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({this.variant = ShimmerVariant.listTile, super.key});

  final ShimmerVariant variant;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PulseTokens.standard.durationSlow,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pulseColors;
    final tokens = context.pulseTokens;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final base = colors.chipUnselectedFill;
        final highlight = Color.lerp(base, colors.borderSubtle, t)!;

        return switch (widget.variant) {
          ShimmerVariant.listTile => _ListTileSkeleton(
            color: highlight,
            tokens: tokens,
          ),
          ShimmerVariant.detailHeader => _DetailSkeleton(
            color: highlight,
            tokens: tokens,
          ),
        };
      },
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton({required this.color, required this.tokens});

  final Color color;
  final PulseTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tokens.listTileHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.color, required this.tokens});

  final Color color;
  final PulseTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          width: 180,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
        ),
        SizedBox(height: tokens.spacingMd),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
        ),
      ],
    );
  }
}
