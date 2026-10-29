// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'local_file.dart';

/// Opens the browser file picker and returns the selected file.
///
/// The result of [html.FileReader.readAsArrayBuffer] is not guaranteed to be a
/// [ByteBuffer] on every web target: dart2js returns a [Uint8List] backed by a
/// native `Uint8Array` (runtime type `NativeUint8List`) for `readAsArrayBuffer`,
/// which made the previous `reader.result as ByteBuffer` cast throw
/// "type 'NativeUint8List' is not a subtype of type 'ByteBuffer'" and broke
/// every tool on the web client.
Future<LocalFileSelection?> pickLocalFile() {
  final completer = Completer<LocalFileSelection?>();
  final input = html.FileUploadInputElement()..style.display = 'none';
  html.document.body?.append(input);

  input.onChange.first.then((_) {
    final file = input.files?.firstOrNull;
    input.remove();
    if (file == null) {
      if (!completer.isCompleted) completer.complete();
      return;
    }
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      if (completer.isCompleted) return;
      final bytes = _bytesFromReaderResult(reader.result);
      if (bytes == null) {
        completer.complete();
      } else {
        completer.complete(LocalFileSelection(name: file.name, bytes: bytes));
      }
    });
    reader.onError.first.then((_) {
      // Surface a cancelled/failed read as "nothing picked" instead of leaving
      // the caller's future pending or throwing an uncaught async error.
      if (!completer.isCompleted) completer.complete();
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}

Uint8List? _bytesFromReaderResult(Object? result) {
  if (result is ByteBuffer) return result.asUint8List();
  if (result is Uint8List) return result;
  if (result is List<int>) return Uint8List.fromList(result);
  return null;
}

Future<String?> saveLocalFile(List<int> bytes, String fileName) async {
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  Future<void>.delayed(const Duration(seconds: 1), () {
    html.Url.revokeObjectUrl(url);
  });
  return fileName;
}