import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 骨架屏：加载中的占位，带极轻的呼吸动画；尊重 reduce-motion。
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final base = scheme.surfaceContainerHigh;
    final highlight = Color.alphaBlend(
      scheme.surface.withValues(alpha: 0.55),
      base,
    );
    if (reduceMotion) {
      return _box(base);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _box(Color.lerp(base, highlight, _controller.value)!);
      },
    );
  }

  Widget _box(Color color) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(widget.radius),
    ),
  );
}

/// 多行骨架：列表加载态复用。
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({
    super.key,
    this.lines = 3,
    this.spacing = OcSpace.sm,
    this.widths = const <double?>[],
  });

  final int lines;
  final double spacing;
  final List<double?> widths;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines; index++) ...[
          if (index > 0) SizedBox(height: spacing),
          Skeleton(
            width: widths.length > index ? widths[index] : null,
            height: index == 0 ? 16 : 12,
          ),
        ],
      ],
    );
  }
}