import 'package:flutter/widgets.dart';

import 'file_drop_types.dart';

export 'file_drop_types.dart' show DroppedFile;

/// 非 Web 平台：原生拖放需要额外插件（pubspec 由 client-core 维护），
/// 这里保持透明包裹，行为退化为「点击选择文件」。
Widget ocFileDropRegion({
  required Widget child,
  required ValueChanged<List<DroppedFile>> onDrop,
  ValueChanged<bool>? onDragChanged,
}) => child;