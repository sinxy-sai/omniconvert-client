import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// OmniConvert 自有线性图标体系。
///
/// 约定（与设计基线一致）：
/// * 24×24 网格，内容安全区 3–21；
/// * 1.75px 描边、圆头端点、圆角连接；
/// * 只用 `dart:ui` 的 Path 绘制，不依赖 Material 图标字体，
///   因此描边色可随浅色 / 暗色主题自适应，16px 下仍可辨识。
///
/// 图标数据用「子路径字符串 + 圆角矩形 + 圆」描述，字符串语法只支持
/// 绝对坐标 M / L / C / Q / Z（作者可控，无需引入第三方 SVG 解析器）。
@immutable
class OcIconData {
  const OcIconData(
    this.name, {
    this.paths = const <String>[],
    this.rects = const <OcRect>[],
    this.circles = const <OcCircle>[],
    this.dots = const <OcCircle>[],
    this.fillPaths = const <String>[],
  });

  final String name;
  final List<String> paths;
  final List<OcRect> rects;
  final List<OcCircle> circles;
  final List<OcCircle> dots;
  final List<String> fillPaths;
}

@immutable
class OcRect {
  const OcRect(this.left, this.top, this.width, this.height, this.radius);

  final double left;
  final double top;
  final double width;
  final double height;
  final double radius;
}

@immutable
class OcCircle {
  const OcCircle(this.cx, this.cy, this.radius);

  final double cx;
  final double cy;
  final double radius;
}

/// 图标集合：4 个导航项 + 6 个工具 + 常用界面图标。
abstract final class OcIcons {
  // ---------------- 导航 ----------------
  static const home = OcIconData(
    'home',
    paths: <String>[
      'M3.4 10.5 L12 3.7 L20.6 10.5',
      'M5.7 9.4 L5.7 18.9 Q5.7 20.4 7.2 20.4 L16.8 20.4 Q18.3 20.4 18.3 18.9 L18.3 9.4',
      'M9.9 20.4 L9.9 15.2 Q9.9 14 11.1 14 L12.9 14 Q14.1 14 14.1 15.2 L14.1 20.4',
    ],
  );

  static const tools = OcIconData(
    'tools',
    rects: <OcRect>[
      OcRect(4, 4, 6.3, 6.3, 1.9),
      OcRect(13.7, 4, 6.3, 6.3, 1.9),
      OcRect(4, 13.7, 6.3, 6.3, 1.9),
      OcRect(13.7, 13.7, 6.3, 6.3, 1.9),
    ],
  );

  static const tasks = OcIconData(
    'tasks',
    rects: <OcRect>[OcRect(4.4, 3.4, 15.2, 17.2, 3.2)],
    paths: <String>[
      'M8.3 9.4 L15.7 9.4',
      'M8.3 13 L15.7 13',
      'M8.3 16.6 L12.9 16.6',
    ],
  );

  static const settings = OcIconData(
    'settings',
    paths: <String>['M4 8.2 L20 8.2', 'M4 16.2 L20 16.2'],
    circles: <OcCircle>[OcCircle(9.2, 8.2, 2.3), OcCircle(15, 16.2, 2.3)],
  );

  // ---------------- 工具 ----------------
  /// 图片互相转换：两个方向箭头。
  static const convert = OcIconData(
    'convert',
    paths: <String>[
      'M7.4 7.6 L16.6 7.6',
      'M13.9 5.1 L16.8 7.6 L13.9 10.1',
      'M16.6 16.4 L7.4 16.4',
      'M10.1 13.9 L7.2 16.4 L10.1 18.9',
    ],
  );

  /// 图片：相框 + 山 + 太阳。
  static const image = OcIconData(
    'image',
    rects: <OcRect>[OcRect(3.6, 4.6, 16.8, 14.8, 3)],
    paths: <String>[
      'M4.3 16.2 L8.4 12.1 Q9.1 11.4 9.8 12.1 L12.5 14.8 L14.4 12.9 L16.7 15.2',
    ],
    circles: <OcCircle>[OcCircle(8.6, 9.2, 1.5)],
  );

  /// 压缩：向中间收拢的双箭头。
  static const compress = OcIconData(
    'compress',
    paths: <String>[
      'M12 3.8 L12 9.1',
      'M9.5 6.6 L12 9.1 L14.5 6.6',
      'M12 20.2 L12 14.9',
      'M9.5 17.4 L12 14.9 L14.5 17.4',
      'M4.4 12 L7.4 12',
      'M16.6 12 L19.6 12',
    ],
  );

  /// 图片 → PDF：页面 + 内嵌图片。
  static const imageToPdf = OcIconData(
    'imageToPdf',
    paths: <String>[
      'M6.5 3.6 L13.3 3.6 L17.6 7.9 L17.6 18.7 Q17.6 20.3 16 20.3 L8 20.3 Q6.5 20.3 6.5 18.7 Z',
      'M13.3 3.6 L13.3 7.9 L17.6 7.9',
    ],
    rects: <OcRect>[OcRect(8.7, 11.6, 6.6, 5.4, 1.2)],
  );

  /// 文档 → PDF：页面 + 文字行。
  static const document = OcIconData(
    'document',
    paths: <String>[
      'M6.5 3.6 L13.3 3.6 L17.6 7.9 L17.6 18.7 Q17.6 20.3 16 20.3 L8 20.3 Q6.5 20.3 6.5 18.7 Z',
      'M13.3 3.6 L13.3 7.9 L17.6 7.9',
      'M9.2 11.8 L14.9 11.8',
      'M9.2 14.8 L14.9 14.8',
      'M9.2 17.4 L12.4 17.4',
    ],
  );

  /// 电子书 → PDF：书本。
  static const book = OcIconData(
    'book',
    paths: <String>[
      'M6.2 4 Q6.2 3.3 6.9 3.3 L17.4 3.3 Q18.1 3.3 18.1 4 L18.1 20 Q18.1 20.7 17.4 20.7 L6.9 20.7 Q6.2 20.7 6.2 20 Z',
      'M9.6 3.3 L9.6 20.7',
      'M12.2 8.2 L15.8 8.2',
      'M12.2 11.4 L15.8 11.4',
      'M12.2 14.6 L14.4 14.6',
    ],
  );

  // ---------------- 界面 ----------------
  static const upload = OcIconData(
    'upload',
    paths: <String>[
      'M12 16.4 L12 4.6',
      'M7.8 8.8 L12 4.6 L16.2 8.8',
      'M4.7 15.4 L4.7 18.1 Q4.7 20.2 6.8 20.2 L17.2 20.2 Q19.3 20.2 19.3 18.1 L19.3 15.4',
    ],
  );

  static const download = OcIconData(
    'download',
    paths: <String>[
      'M12 4.4 L12 15.6',
      'M7.8 11.4 L12 15.6 L16.2 11.4',
      'M4.7 15.8 L4.7 18.1 Q4.7 20.2 6.8 20.2 L17.2 20.2 Q19.3 20.2 19.3 18.1 L19.3 15.8',
    ],
  );

  static const close = OcIconData(
    'close',
    paths: <String>['M7 7 L17 17', 'M17 7 L7 17'],
  );

  static const check = OcIconData(
    'check',
    paths: <String>['M5.2 12.6 L9.9 17.3 L18.8 7.4'],
  );

  static const alert = OcIconData(
    'alert',
    paths: <String>[
      'M12 4.4 L20.7 19.4 Q21.1 20.4 20 20.4 L4 20.4 Q2.9 20.4 3.3 19.4 Z',
      'M12 9.8 L12 14.4',
    ],
    dots: <OcCircle>[OcCircle(12, 17.3, 0.95)],
  );

  static const info = OcIconData(
    'info',
    circles: <OcCircle>[OcCircle(12, 12, 8.6)],
    paths: <String>['M12 10.9 L12 16.4'],
    dots: <OcCircle>[OcCircle(12, 7.9, 0.95)],
  );

  static const refresh = OcIconData(
    'refresh',
    paths: <String>[
      'M19.5 12 C19.5 7.7 16.1 4.3 11.8 4.3 C8.5 4.3 5.6 6.4 4.5 9.5',
      'M4.3 5.4 L4.5 9.7 L8.8 9.3',
      'M4.5 12 C4.5 16.3 7.9 19.7 12.2 19.7 C15.5 19.7 18.4 17.6 19.5 14.5',
      'M19.7 18.6 L19.5 14.3 L15.2 14.7',
    ],
  );

  static const chevronRight = OcIconData(
    'chevronRight',
    paths: <String>['M9.6 5.6 L16 12 L9.6 18.4'],
  );

  static const chevronDown = OcIconData(
    'chevronDown',
    paths: <String>['M5.6 9.4 L12 15.8 L18.4 9.4'],
  );

  static const arrowRight = OcIconData(
    'arrowRight',
    paths: <String>['M4.6 12 L19.2 12', 'M13.9 6.7 L19.2 12 L13.9 17.3'],
  );

  static const folder = OcIconData(
    'folder',
    paths: <String>[
      'M3.8 7.4 Q3.8 5.8 5.4 5.8 L9.3 5.8 L11.1 8 L18.6 8 Q20.2 8 20.2 9.6 L20.2 17.4 Q20.2 19 18.6 19 L5.4 19 Q3.8 19 3.8 17.4 Z',
    ],
  );

  static const shield = OcIconData(
    'shield',
    paths: <String>[
      'M12 3.6 L19.4 6.4 L19.4 12 C19.4 16.4 16.2 19.4 12 20.6 C7.8 19.4 4.6 16.4 4.6 12 L4.6 6.4 Z',
      'M8.9 12.1 L11.3 14.5 L15.4 10.2',
    ],
  );

  static const lock = OcIconData(
    'lock',
    paths: <String>[
      'M7.6 10.6 L16.4 10.6 Q17.7 10.6 17.7 11.9 L17.7 18.3 Q17.7 19.6 16.4 19.6 L7.6 19.6 Q6.3 19.6 6.3 18.3 L6.3 11.9 Q6.3 10.6 7.6 10.6 Z',
      'M9 10.6 L9 8.4 C9 6.7 10.3 5.4 12 5.4 C13.7 5.4 15 6.7 15 8.4 L15 10.6',
    ],
  );

  static const sun = OcIconData(
    'sun',
    circles: <OcCircle>[OcCircle(12, 12, 4.2)],
    paths: <String>[
      'M12 2.6 L12 4.6',
      'M12 19.4 L12 21.4',
      'M2.6 12 L4.6 12',
      'M19.4 12 L21.4 12',
      'M5.4 5.4 L6.8 6.8',
      'M17.2 17.2 L18.6 18.6',
      'M18.6 5.4 L17.2 6.8',
      'M6.8 17.2 L5.4 18.6',
    ],
  );

  static const moon = OcIconData(
    'moon',
    paths: <String>[
      'M20.3 14.9 C19 18 15.7 20.2 12 20.2 C7.3 20.2 3.5 16.4 3.5 11.7 C3.5 7.9 6 4.7 9.4 3.6 C8.4 5.5 7.9 7.6 7.9 9.9 C7.9 15.6 12.5 20.2 18.2 20.2 C18.9 20.2 19.6 20.1 20.3 19.9',
    ],
  );

  static const monitor = OcIconData(
    'monitor',
    rects: <OcRect>[OcRect(3.4, 5.2, 17.2, 11.8, 2.4)],
    paths: <String>['M12 17 L12 20.4', 'M8.8 20.4 L15.2 20.4'],
  );

  static const play = OcIconData(
    'play',
    fillPaths: <String>['M9.2 6.2 L18.2 12 L9.2 17.8 Z'],
  );

  static const stop = OcIconData(
    'stop',
    rects: <OcRect>[OcRect(8.4, 8.4, 7.2, 7.2, 1.8)],
  );

  static const plus = OcIconData(
    'plus',
    paths: <String>['M12 5.4 L12 18.6', 'M5.4 12 L18.6 12'],
  );

  static const trash = OcIconData(
    'trash',
    paths: <String>[
      'M4.6 7.4 L19.4 7.4',
      'M9.4 7.4 L9.4 5.5 Q9.4 4.6 10.3 4.6 L13.7 4.6 Q14.6 4.6 14.6 5.5 L14.6 7.4',
      'M6.7 7.4 L7.5 19 Q7.6 20.2 8.8 20.2 L15.2 20.2 Q16.4 20.2 16.5 19 L17.3 7.4',
    ],
  );

  static const sparkle = OcIconData(
    'sparkle',
    paths: <String>[
      'M5.2 19 L15.4 8.8',
      'M13.7 7.1 L16.9 10.3',
      'M17.8 3.9 L17.8 7.5',
      'M16 5.7 L19.6 5.7',
      'M5.4 5.2 L5.4 8.4',
      'M3.8 6.8 L7 6.8',
    ],
  );

  static const clock = OcIconData(
    'clock',
    circles: <OcCircle>[OcCircle(12, 12, 8.6)],
    paths: <String>['M12 7.4 L12 12.2 L15.6 14.2'],
  );

  static const chip = OcIconData(
    'chip',
    rects: <OcRect>[OcRect(6.4, 6.4, 11.2, 11.2, 2.4)],
    paths: <String>[
      'M9.9 10.4 L14.1 10.4 L14.1 13.6 L9.9 13.6 Z',
      'M12 6.4 L12 3.8',
      'M8 6.4 L8 3.8',
      'M16 6.4 L16 3.8',
      'M12 17.6 L12 20.2',
      'M8 17.6 L8 20.2',
      'M16 17.6 L16 20.2',
      'M6.4 12 L3.8 12',
      'M6.4 8 L3.8 8',
      'M6.4 16 L3.8 16',
      'M17.6 12 L20.2 12',
      'M17.6 8 L20.2 8',
      'M17.6 16 L20.2 16',
    ],
  );

  static const cloud = OcIconData(
    'cloud',
    paths: <String>[
      'M7.5 18.6 C4.9 18.6 3 16.7 3 14.1 C3 11.9 4.5 10 6.7 9.6 C7.3 6.5 10 4.3 13 4.3 C16.4 4.3 19.1 6.9 19.3 10.3 C20.8 10.9 21.8 12.4 21.8 14.1 C21.8 16.5 19.9 18.6 17.5 18.6 Z',
    ],
  );

  static const file = OcIconData(
    'file',
    paths: <String>[
      'M6 3.6 L13.2 3.6 L18 8.4 L18 18.7 Q18 20.4 16.3 20.4 L7.7 20.4 Q6 20.4 6 18.7 Z',
      'M13.2 3.6 L13.2 8.4 L18 8.4',
    ],
  );

  static const external = OcIconData(
    'external',
    paths: <String>[
      'M14.2 4.6 L19.4 4.6 L19.4 9.8',
      'M19.4 4.6 L11.3 12.7',
      'M18 14.4 L18 18.6 Q18 20 16.6 20 L5.4 20 Q4 20 4 18.6 L4 7.4 Q4 6 5.4 6 L9.6 6',
    ],
  );

  static const copy = OcIconData(
    'copy',
    rects: <OcRect>[OcRect(9, 9, 11.4, 11.4, 2.4)],
    paths: <String>[
      'M15.6 6.2 Q15.6 3.8 13.2 3.8 L6.2 3.8 Q3.8 3.8 3.8 6.2 L3.8 13.2 Q3.8 15.6 6.2 15.6',
    ],
  );

  static const list = OcIconData(
    'list',
    paths: <String>[
      'M8.6 6.6 L20 6.6',
      'M8.6 12 L20 12',
      'M8.6 17.4 L20 17.4',
    ],
    dots: <OcCircle>[
      OcCircle(4.8, 6.6, 1.1),
      OcCircle(4.8, 12, 1.1),
      OcCircle(4.8, 17.4, 1.1),
    ],
  );

  static const all = <OcIconData>[
    home,
    tools,
    tasks,
    settings,
    convert,
    image,
    compress,
    imageToPdf,
    document,
    book,
    upload,
    download,
    close,
    check,
    alert,
    info,
    refresh,
    chevronRight,
    chevronDown,
    arrowRight,
    folder,
    shield,
    lock,
    sun,
    moon,
    monitor,
    play,
    stop,
    plus,
    trash,
    sparkle,
    clock,
    chip,
    cloud,
    file,
    external,
    copy,
    list,
  ];
}

/// 绘制 [OcIconData] 的组件：颜色默认取 IconTheme，尺寸默认 20。
class OcIcon extends StatelessWidget {
  const OcIcon(
    this.data, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth,
  });

  final OcIconData data;
  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolved = color ?? iconTheme.color ?? const Color(0xFF475569);
    // 24 网格下 1.75 描边；放大 / 缩小时按比例微调，16px 仍保持可辨识。
    final pixelStroke =
        strokeWidth ?? (size * 0.0729).clamp(1.45, 2.2);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OcIconPainter(
          data: data,
          color: resolved,
          strokeIn24: pixelStroke * 24 / size,
        ),
      ),
    );
  }
}

class _OcIconPainter extends CustomPainter {
  const _OcIconPainter({
    required this.data,
    required this.color,
    required this.strokeIn24,
  });

  final OcIconData data;
  final Color color;
  final double strokeIn24;

  static final Map<String, List<Path>> _cache = <String, List<Path>>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24.0;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeIn24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paths = _cache.putIfAbsent(data.name, () => _buildPaths(data));
    for (final path in paths) {
      canvas.drawPath(path, stroke);
    }
    for (final path in data.fillPaths) {
      canvas.drawPath(_parse(path), fill);
    }
    for (final rect in data.rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
          Radius.circular(rect.radius),
        ),
        stroke,
      );
    }
    for (final circle in data.circles) {
      canvas.drawCircle(Offset(circle.cx, circle.cy), circle.radius, stroke);
    }
    for (final dot in data.dots) {
      canvas.drawCircle(Offset(dot.cx, dot.cy), dot.radius, fill);
    }
    canvas.restore();
  }

  static List<Path> _buildPaths(OcIconData data) {
    final result = <Path>[];
    for (final source in data.paths) {
      result.add(_parse(source));
    }
    return result;
  }

  /// 极简路径解析：只支持绝对坐标的 M / L / C / Q / Z 及其重复参数。
  static Path _parse(String source) {
    final tokens = _tokenize(source);
    final path = Path();
    var index = 0;
    var command = '';
    double next() => tokens[index++] as double;

    while (index < tokens.length) {
      final token = tokens[index];
      if (token is String) {
        command = token;
        index += 1;
        if (command == 'Z') {
          path.close();
          continue;
        }
      }
      if (command == 'M') {
        path.moveTo(next(), next());
        // 连续的坐标对按 L 处理（SVG 语义）。
        command = 'L';
      } else if (command == 'L') {
        path.lineTo(next(), next());
      } else if (command == 'C') {
        path.cubicTo(next(), next(), next(), next(), next(), next());
      } else if (command == 'Q') {
        path.quadraticBezierTo(next(), next(), next(), next());
      } else {
        index += 1;
      }
    }
    return path;
  }

  static List<Object> _tokenize(String source) {
    final tokens = <Object>[];
    final number = StringBuffer();
    void flush() {
      if (number.isEmpty) return;
      tokens.add(double.parse(number.toString()));
      number.clear();
    }

    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == ' ') {
        flush();
        continue;
      }
      final isCommand = const {'M', 'L', 'C', 'Q', 'Z'}.contains(char);
      if (isCommand) {
        flush();
        tokens.add(char);
        continue;
      }
      if (char == '-' && number.isNotEmpty) flush();
      number.write(char);
    }
    flush();
    return tokens;
  }

  @override
  bool shouldRepaint(covariant _OcIconPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.color != color ||
      oldDelegate.strokeIn24 != strokeIn24;
}

/// 供需要自行绘制时使用的工具：把图标数据画进任意 canvas。
void paintOcIcon(
  Canvas canvas,
  OcIconData data,
  Size size, {
  required Color color,
  double strokeWidth = 1.75,
}) {
  _OcIconPainter(data: data, color: color, strokeIn24: strokeWidth)
      .paint(canvas, size);
}

/// 4 × 4 的圆点矩阵图案，用作 hero / 空态的极浅底纹。
class OcDotPatternPainter extends CustomPainter {
  const OcDotPatternPainter({
    required this.color,
    this.spacing = 18,
    this.radius = 1.1,
  });

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcDotPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// 柔和的品牌光斑（hero 背景）：两团径向渐变 + 轻微旋转，避免死板的纯色块。
class OcAuroraPainter extends CustomPainter {
  const OcAuroraPainter({
    required this.primary,
    required this.secondary,
    this.intensity = 1,
  });

  final Color primary;
  final Color secondary;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    void blob(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(
      Offset(size.width * 0.12, size.height * 0.06),
      math.max(size.width, size.height) * 0.72,
      primary.withValues(alpha: 0.30 * intensity),
    );
    blob(
      Offset(size.width * 0.96, size.height * 0.98),
      math.max(size.width, size.height) * 0.68,
      secondary.withValues(alpha: 0.22 * intensity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OcAuroraPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.intensity != intensity;
}