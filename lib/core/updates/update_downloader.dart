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
  const UpdateDownloader({this.client, this.save = saveUpdate});
  final http.Client? client;
  final Future<String> Function(String, Stream<List<int>>) save;

  Future<String> download(
    ReleaseArtifact release, {
    void Function(DownloadProgress progress)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      if (release.downloadUrl.scheme != 'https') throw const FormatException('Download must use HTTPS');
      final request = http.Request('GET', release.downloadUrl)..followRedirects = false;
      final response = await httpClient.send(request);
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
      return await save('update.apk', stream);
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
}
