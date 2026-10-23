import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:omniconvert/core/updates/release_manifest.dart';
import 'package:omniconvert/core/updates/update_downloader.dart';

void main() {
  final release = ReleaseArtifact(
    platform: 'android', arch: 'arm64-v8a', version: '1.0.0',
    minimumSupportedVersion: '1.0.0', downloadUrl: Uri.parse('https://example.com/app.apk'),
    sha256: 'a' * 64, releaseNotes: 'notes',
  );

  test('reports progress and rejects cancelled downloads', () async {
    final client = _StreamClient();
    final progress = <DownloadProgress>[];
    expect(
      () => UpdateDownloader(client: client).download(release, onProgress: progress.add, isCancelled: () async => true),
      throwsA(isA<UpdateDownloadCancelled>()),
    );
    expect(progress, isEmpty);
  });
}

class _StreamClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(Stream.value(Uint8List.fromList([1, 2, 3])), 200, contentLength: 3);
}
