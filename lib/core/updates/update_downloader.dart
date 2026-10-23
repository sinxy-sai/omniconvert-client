import 'dart:async';

import 'package:http/http.dart' as http;

import 'release_manifest.dart';
import 'update_storage.dart';

class DownloadProgress {
  const DownloadProgress(this.received, this.total);
  final int received;
  final int? total;
}

class UpdateDownloader {
  const UpdateDownloader({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<String> download(
    ReleaseArtifact release, {
    void Function(DownloadProgress progress)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    final client = _client ?? http.Client();
    try {
      final response = await client.send(http.Request('GET', release.downloadUrl));
      if (response.statusCode != 200) throw StateError('Download failed with HTTP ${response.statusCode}');
      var received = 0;
      final stream = response.stream.asyncMap((chunk) async {
          if (await (isCancelled?.call() ?? Future.value(false))) {
            throw const UpdateDownloadCancelled();
          }
          received += chunk.length;
          onProgress?.call(DownloadProgress(received, response.contentLength));
          return chunk;
        });
      return await saveUpdate('update.apk', stream);
    } finally {
      if (_client == null) client.close();
    }
  }
}

class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
}
