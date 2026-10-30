import 'dart:typed_data';

/// 从窗口拖入的一个文件。
class DroppedFile {
  const DroppedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get length => bytes.length;
}