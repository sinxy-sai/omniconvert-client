import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'local_file.dart';

Future<LocalFileSelection?> pickLocalImage() async {
  const typeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['png', 'jpg', 'jpeg', 'webp'],
  );
  final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
  if (file == null) return null;
  return LocalFileSelection(
    name: file.name,
    path: file.path,
    bytes: await File(file.path).readAsBytes(),
  );
}

Future<String?> saveLocalFile(List<int> bytes, String fileName) async {
  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null) return null;
  await XFile.fromData(Uint8List.fromList(bytes), name: fileName).saveTo(location.path);
  return location.path;
}

void downloadLocalFile(List<int> bytes, String fileName) {}
