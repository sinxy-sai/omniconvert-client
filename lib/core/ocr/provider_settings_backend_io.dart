import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'provider_settings.dart';

class _FileBackend implements OcrProviderSettingsBackend {
  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/ocr-provider-endpoint.txt');
  }

  @override
  Future<String?> readEndpoint() async {
    final file = await _file;
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> writeEndpoint(String? endpoint) async {
    final file = await _file;
    if (endpoint == null) {
      if (file.existsSync()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(endpoint, flush: true);
  }
}

OcrProviderSettingsBackend createBackend() => _FileBackend();
