import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveUpdate(String fileName, Stream<List<int>> bytes) async {
  final directory = await getApplicationSupportDirectory();
  final updates = Directory('${directory.path}/updates')..createSync(recursive: true);
  final file = File('${updates.path}/$fileName');
  try {
    final sink = file.openWrite();
    await sink.addStream(bytes);
    await sink.flush();
    await sink.close();
    return file.path;
  } catch (_) {
    if (await file.exists()) await file.delete();
    rethrow;
  }
}
