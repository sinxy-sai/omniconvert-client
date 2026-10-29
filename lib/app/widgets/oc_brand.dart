import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 品牌 mark（应用内版本）：品牌渐变底上的「O + C 双环 + 转换箭头」。
///
/// 正式品牌资产（SVG/ICO）由品牌任务输出，这里只用于客户端界面内的品牌区，
/// 不写死外部资源，避免与品牌任务互相覆盖。
class OcBrandMark extends StatelessWidget {
  const OcBrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandMarkPainter(isDark: OcSemantics.of(context).isDark)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.3);
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [OcColor.brand, OcColor.accent],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), background);

    final stroke = size.width * 0.082;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final centerY = size.height * 0.5;
    final ringRadius = size.width * 0.165;

    // O：完整圆环。
    canvas.drawCircle(
      Offset(size.width * 0.345, centerY),
      ringRadius,
      white,
    );

    // C：右侧开口的双环之一。
    final cCenter = Offset(size.width * 0.575, centerY);
    canvas.drawArc(
      Rect.fromCircle(center: cCenter, radius: ringRadius),
      -math.pi * 0.28,
      math.pi * 1.56,
      false,
      white,
    );

    // 转换箭头：指向 C 的开口，暗示「格式互换」。
    final arrow = Path()
      ..moveTo(size.width * 0.735, centerY - size.height * 0.07)
      ..lineTo(size.width * 0.805, centerY)
      ..lineTo(size.width * 0.735, centerY + size.height * 0.07);
    canvas.drawPath(arrow, white);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// 品牌区组合：mark + 字标（可选口号）。
class OcBrandLockup extends StatelessWidget {
  const OcBrandLockup({
    super.key,
    this.markSize = 34,
    this.showTagline = false,
    this.titleStyle,
  });

  final double markSize;
  final bool showTagline;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OcBrandMark(size: markSize),
        const SizedBox(width: OcSpace.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OmniConvert',
              style: (titleStyle ?? textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (showTagline)
              Text(
                '文件处理，简单一点。',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
  }
}