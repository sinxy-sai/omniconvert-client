// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'local_file.dart';

Future<LocalFileSelection?> pickLocalImage() {
  final completer = Completer<LocalFileSelection?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.onChange.first.then((_) async {
    final file = input.files?.firstOrNull;
    if (file == null) {
      completer.complete();
      return;
    }
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      completer.complete(
        LocalFileSelection(
          name: file.name,
          bytes: Uint8List.view(reader.result as ByteBuffer),
        ),
      );
    });
    reader.readAsArrayBuffer(file);
  });
  input.click();
  return completer.future;
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
