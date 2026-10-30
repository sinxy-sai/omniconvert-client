import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 品牌标识：承载「转换」这件事的最小几何。
///
/// 结构（24×24 概念网格上的双环 + 箭头）：
/// * 左环：完整的 O，代表「原始文件」；
/// * 右弧：开口的 C，代表「转换后的文件」；
/// * 箭头：从 O 指向 C 的开口，代表「格式流动」。
///
/// 用 CustomPainter 绘制而不是图标字体，暗色下描边自适应，16px 仍可辨识。
class OcBrandMark extends StatelessWidget {
  const OcBrandMark({super.key, this.size = 40, this.invert = false});

  final double size;

  /// true 时用于深色底（侧栏 / 页面 hero 的深底版本）。
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final semantics = OcSemantics.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          gradient: semantics.brandGradient,
          invert: invert,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.gradient, required this.invert});

  final LinearGradient gradient;
  final bool invert;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final rect = Offset.zero & size;

    if (invert) {
      // 深底上不做实心块，直接用白色双环，避免「贴纸感」。
      _glyph(canvas, unit, Colors.white);
      return;
    }

    final radius = Radius.circular(size.width * 0.29);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..shader = gradient.createShader(rect),
    );
    // 顶部一层极淡高光，让渐变块有体积。
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    _glyph(canvas, unit, Colors.white);
  }

  void _glyph(Canvas canvas, double unit, Color color) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final centerY = 12 * unit;

    // O：完整圆环。
    canvas.drawCircle(Offset(8.9 * unit, centerY), 3.5 * unit, stroke);

    // C：右侧开口圆环（留出右边 60° 的缺口给箭头）。
    final cCenter = Offset(15.4 * unit, centerY);
    canvas.drawArc(
      Rect.fromCircle(center: cCenter, radius: 3.5 * unit),
      -math.pi * 0.62,
      math.pi * 1.44,
      false,
      stroke,
    );

    // 箭头：指向 C 的缺口，同时暗示「格式移动」。
    final arrow = Path()
      ..moveTo(15.9 * unit, 7.7 * unit)
      ..lineTo(18.9 * unit, centerY)
      ..lineTo(15.9 * unit, 16.3 * unit);
    canvas.drawPath(arrow, stroke);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.gradient != gradient || oldDelegate.invert != invert;
}

/// 品牌组合：mark + 字标（可选口号）。
class OcBrandLockup extends StatelessWidget {
  const OcBrandLockup({
    super.key,
    this.markSize = 34,
    this.showTagline = false,
    this.invert = false,
    this.dense = false,
    this.titleStyle,
  });

  final double markSize;
  final bool showTagline;
  final bool invert;
  final bool dense;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);
    final titleColor = invert ? semantics.navInk : null;
    final taglineColor = invert ? semantics.navInkSoft : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OcBrandMark(size: markSize, invert: invert),
        SizedBox(width: dense ? OcSpace.xs : OcSpace.sm),
        // 侧栏只有 250dp，字标必须能收缩：否则宽屏侧栏会 RenderFlex overflow
        // （mark 36 + 标题 + 口号 加起来超过 202dp）。省略号而不是溢出。
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OmniConvert',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (titleStyle ??
                            (dense
                                ? textTheme.titleMedium
                                : textTheme.titleLarge))
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: titleColor,
                        ),
              ),
              if (showTagline)
                Text(
                  '文件处理，简单一点',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: taglineColor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}