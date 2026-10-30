import 'dart:io';
import 'dart:typed_data';

import 'output_file_name.dart' show baseFileName;

/// Reads the whole input file, or `null` when it cannot be read.
///
/// Any [FileSystemException] is swallowed into `null` on purpose: the runner
/// turns that into a readable `InvalidInput` failure instead of leaking a
/// platform specific error into the UI.
Future<Uint8List?> readToolInputBytes(String path) async {
  if (path.isEmpty) return null;
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } on FileSystemException {
    return null;
  }
}

/// Working directory for outputs the caller only knows by *name*.
///
/// Kept inside the system temp root (never a path the app was not given) but
/// with a stable sub folder, so the name shown to the user is exactly the name
/// they asked for — the previous implementation prefixed the name with a
/// microsecond stamp (`1700000000-photo.jpg`), which made the "已保存到 …" line
/// unrecognisable and impossible to search for.
String get _toolOutputDirectory =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}OmniConvert';

/// Writes produced bytes and returns the path that was actually written.
///
/// A bare file name (no directory separator) is placed in [_toolOutputDirectory];
/// an explicit path is written as given. Missing parent directories are created.
Future<String> writeToolOutputBytes(String path, Uint8List bytes) async {
  final base = baseFileName(path);
  final file = path.contains(RegExp(r'[\\/]')) || base.isEmpty
      ? File(path)
      : File('$_toolOutputDirectory${Platform.pathSeparator}$base');
  final parent = file.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}