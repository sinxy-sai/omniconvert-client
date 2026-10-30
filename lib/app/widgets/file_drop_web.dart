import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

import 'file_drop_types.dart';

export 'file_drop_types.dart' show DroppedFile;

/// Web：把真实的浏览器 drag & drop 事件接到 Flutter。
///
/// Flutter Web 没有内置的文件拖放 API，这里用 `dart:js_interop` 直接监听
/// window 的 dragenter / dragover / dragleave / drop，读完 ArrayBuffer 后
/// 交给 Flutter 侧处理。非 Web 平台见 `file_drop_stub.dart`。
Widget ocFileDropRegion({
  required Widget child,
  required ValueChanged<List<DroppedFile>> onDrop,
  ValueChanged<bool>? onDragChanged,
}) => _WebDropRegion(
  onDrop: onDrop,
  onDragChanged: onDragChanged,
  child: child,
);

@JS('window')
external _Win get _window;

extension type _Win(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _DragEvent(JSObject _) implements JSObject {
  external void preventDefault();
  external void stopPropagation();
  external _DataTransfer? get dataTransfer;
  external JSObject? get relatedTarget;
}

extension type _DataTransfer(JSObject _) implements JSObject {
  external _FileList get files;
  external JSArray<JSObject> get types;
  external String get dropEffect;
  external set dropEffect(String value);
}

extension type _FileList(JSObject _) implements JSObject {
  external int get length;
  external _FileEntry item(int index);
}

extension type _FileEntry(JSObject _) implements JSObject {
  external String get name;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

class _WebDropRegion extends StatefulWidget {
  const _WebDropRegion({
    required this.child,
    required this.onDrop,
    this.onDragChanged,
  });

  final Widget child;
  final ValueChanged<List<DroppedFile>> onDrop;
  final ValueChanged<bool>? onDragChanged;

  @override
  State<_WebDropRegion> createState() => _WebDropRegionState();
}

class _WebDropRegionState extends State<_WebDropRegion> {
  bool _dragging = false;
  late final JSFunction _onDragEnter;
  late final JSFunction _onDragOver;
  late final JSFunction _onDragLeave;
  late final JSFunction _onDrop;
  late final JSFunction _onDragEnd;

  @override
  void initState() {
    super.initState();
    _onDragEnter = ((JSAny event) {
      _setDragging(true);
    }).toJS;
    _onDragOver = ((JSAny event) {
      // 必须阻止默认行为，否则浏览器不会派发 drop。
      _DragEvent(event as JSObject).preventDefault();
      _setDragging(true);
    }).toJS;
    _onDragLeave = ((JSAny event) {
      final target = _DragEvent(event as JSObject);
      // 只有真正离开窗口时才收起高亮，避免子元素抖动。
      if (target.relatedTarget == null) _setDragging(false);
    }).toJS;
    _onDragEnd = ((JSAny event) => _setDragging(false)).toJS;
    _onDrop = ((JSAny event) {
      final dragEvent = _DragEvent(event as JSObject);
      dragEvent.preventDefault();
      dragEvent.stopPropagation();
      _setDragging(false);
      final transfer = dragEvent.dataTransfer;
      if (transfer == null) return;
      unawaited(_readFiles(transfer));
    }).toJS;

    _window.addEventListener('dragenter', _onDragEnter);
    _window.addEventListener('dragover', _onDragOver);
    _window.addEventListener('dragleave', _onDragLeave);
    _window.addEventListener('dragend', _onDragEnd);
    _window.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    _window.removeEventListener('dragenter', _onDragEnter);
    _window.removeEventListener('dragover', _onDragOver);
    _window.removeEventListener('dragleave', _onDragLeave);
    _window.removeEventListener('dragend', _onDragEnd);
    _window.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    widget.onDragChanged?.call(value);
  }

  Future<void> _readFiles(_DataTransfer transfer) async {
    final list = transfer.files;
    final files = <DroppedFile>[];
    for (var index = 0; index < list.length; index++) {
      final entry = list.item(index);
      try {
        final buffer = await entry.arrayBuffer().toDart;
        files.add(
          DroppedFile(
            name: entry.name,
            bytes: buffer.toDart.asUint8List(),
          ),
        );
      } catch (_) {
        // 单个文件读取失败不影响其它文件；上层会给出可读提示。
      }
    }
    if (files.isNotEmpty) widget.onDrop(files);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}