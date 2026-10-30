import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:omniconvert/core/updates/release_manifest.dart';
import 'package:omniconvert/core/updates/update_downloader.dart';

final _payload = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9]);
final _payloadSha = sha256.convert(_payload).toString();

ReleaseArtifact _release({String? sha256Hex}) => ReleaseArtifact(
  platform: 'android',
  arch: 'arm64-v8a',
  version: '1.0.0',
  minimumSupportedVersion: '1.0.0',
  downloadUrl: Uri.parse('https://example.com/app.apk'),
  sha256: sha256Hex ?? _payloadSha,
  releaseNotes: 'notes',
);

class _StreamClient extends http.BaseClient {
  _StreamClient(this.bytes);
  final Uint8List bytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
}

void main() {
  test('reports progress and rejects cancelled downloads', () async {
    final progress = <DownloadProgress>[];
    expect(
      () => UpdateDownloader(
        client: _StreamClient(_payload),
        save: (_, bytes) async {
          await for (final _ in bytes) {}
          return 'update.apk';
        },
        deleteFile: (_) async {},
      ).download(
        _release(),
        onProgress: progress.add,
        isCancelled: () async => true,
      ),
      throwsA(isA<UpdateDownloadCancelled>()),
    );
    expect(progress, isEmpty);
  });

  test('accepts a download whose SHA-256 matches the manifest', () async {
    final progress = <DownloadProgress>[];
    final saved = <int>[];

    final path = await UpdateDownloader(
      client: _StreamClient(_payload),
      save: (name, bytes) async {
        // 文件名从下载地址推导（清单 URL 的最后一段），不再硬编码 update.apk。
        expect(name, 'app.apk');
        await for (final chunk in bytes) {
          saved.addAll(chunk);
        }
        return '/tmp/$name';
      },
      deleteFile: (path) async => fail('a verified download must not be deleted'),
    ).download(_release(), onProgress: progress.add);

    expect(path, '/tmp/app.apk');
    expect(saved, _payload);
    expect(progress, isNotEmpty);
    expect(progress.last.received, _payload.length);
    expect(progress.last.total, _payload.length);
  });

  test('deletes the artifact and throws when SHA-256 does not match', () async {
    final deleted = <String>[];

    await expectLater(
      UpdateDownloader(
        client: _StreamClient(_payload),
        save: (_, bytes) async {
          await for (final _ in bytes) {}
          return '/tmp/update.apk';
        },
        deleteFile: (path) async => deleted.add(path),
      ).download(_release(sha256Hex: 'a' * 64)),
      throwsA(isA<UpdateSha256Mismatch>()),
    );

    expect(deleted, ['/tmp/update.apk'],
        reason: 'a corrupt artifact must never survive verification');
  });

  test('the mismatch error is readable and names no Dart class', () async {
    try {
      await UpdateDownloader(
        client: _StreamClient(_payload),
        save: (_, bytes) async {
          await for (final _ in bytes) {}
          return '/tmp/update.apk';
        },
        deleteFile: (_) async {},
      ).download(_release(sha256Hex: 'b' * 64));
      fail('expected UpdateSha256Mismatch');
    } on UpdateSha256Mismatch catch (error) {
      expect(error.message, contains('校验失败'));
      expect(error.message, isNot(contains('Exception')));
    }
  });

  test('rejects an unusable manifest hash before downloading', () async {
    var requested = false;
    await expectLater(
      UpdateDownloader(
        client: _StreamClient(_payload),
        save: (_, _) async {
          requested = true;
          return 'update.apk';
        },
        deleteFile: (_) async {},
      ).download(_release(sha256Hex: 'not-a-hash')),
      throwsA(isA<UpdateManifestException>()),
    );
    expect(requested, isFalse);
  });
}