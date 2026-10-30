import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'release_manifest.dart';
import 'update_storage.dart';

class DownloadProgress {
  const DownloadProgress(this.received, this.total);
  final int received;
  final int? total;

  /// 0..1，服务器没给 `Content-Length` 时为 null（进度条走不确定态）。
  double? get fraction {
    final total = this.total;
    if (total == null || total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }
}

/// GitHub Release 资产 URL 必然 302 到 CDN，所以重定向必须自己跟；
/// 上限 5 跳，避免被恶意链接拖进死循环。
const int kMaxUpdateRedirectHops = 5;

/// 下载并**强制**校验清单里的 SHA-256。
///
/// * 边下边算摘要，50 MB 的安装包不会被整个读进内存；
/// * 手动跟随重定向，每一跳都要求 HTTPS，最终必须是 200；
/// * 校验失败会删除已经落盘的文件 —— 半成品绝不能进安装器。
class UpdateDownloader {
  const UpdateDownloader({
    this.client,
    this.save = saveUpdate,
    this.deleteFile = deleteUpdate,
  });

  final http.Client? client;
  final Future<String> Function(String, Stream<List<int>>) save;
  final Future<void> Function(String) deleteFile;

  Future<String> download(
    ReleaseArtifact release, {
    void Function(DownloadProgress progress)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    final expected = release.sha256.toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(expected)) {
      throw const UpdateManifestException('发布清单里的 SHA-256 无效，已停止下载。');
    }
    if (release.downloadUrl.scheme != 'https') {
      throw const UpdateManifestException('更新包必须通过 HTTPS 下载。');
    }
    final fileName = updateArtifactFileName(release);
    if (fileName.isEmpty) {
      throw const UpdateManifestException('发布清单里的下载地址没有可用的文件名。');
    }
    final httpClient = client ?? http.Client();
    try {
      final response = await _followRedirects(httpClient, release.downloadUrl);
      final collector = _DigestCollector();
      final hasher = sha256.startChunkedConversion(collector);
      var received = 0;
      final stream = response.stream.asyncMap((chunk) async {
        if (await (isCancelled?.call() ?? Future.value(false))) {
          throw const UpdateDownloadCancelled();
        }
        received += chunk.length;
        onProgress?.call(DownloadProgress(received, response.contentLength));
        hasher.add(chunk);
        return chunk;
      });
      final path = await save(fileName, stream);
      hasher.close();
      final actual = collector.value?.toString() ?? '';
      if (actual != expected) {
        await _deleteQuietly(path);
        throw UpdateSha256Mismatch(expected: expected, actual: actual);
      }
      return path;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Follows up to [kMaxUpdateRedirectHops] redirects, rejecting any hop that is
  /// not HTTPS, and returns the final 200 response.
  Future<http.StreamedResponse> _followRedirects(
    http.Client client,
    Uri start,
  ) async {
    var current = start;
    for (var hop = 0; hop <= kMaxUpdateRedirectHops; hop++) {
      if (current.scheme != 'https') {
        throw const UpdateManifestException('更新包必须通过 HTTPS 下载。');
      }
      final response = await client.send(
        http.Request('GET', current)..followRedirects = false,
      );
      if (!_isRedirect(response.statusCode)) {
        if (response.statusCode != 200) {
          await _drain(response);
          throw UpdateDownloadException(
            '下载安装包失败（HTTP ${response.statusCode}），请稍后重试。',
          );
        }
        return response;
      }
      final location = response.headers['location']?.trim();
      await _drain(response);
      if (location == null || location.isEmpty) {
        throw const UpdateDownloadException('下载地址跳转缺少目标地址，请稍后重试。');
      }
      final next = current.resolve(location);
      if (next.scheme != 'https') {
        throw const UpdateManifestException(
          '下载地址被重定向到非 HTTPS 地址，出于安全考虑已停止下载。',
        );
      }
      current = next;
    }
    throw UpdateDownloadException(
      '下载地址跳转超过 $kMaxUpdateRedirectHops 次，已停止；请稍后重试。',
    );
  }

  static bool _isRedirect(int statusCode) =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;

  /// Releases the socket of a response body we are not going to read.
  static Future<void> _drain(http.StreamedResponse response) async {
    try {
      await response.stream.drain<void>();
    } catch (_) {
      // Nothing to clean up beyond closing the stream.
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await deleteFile(path);
    } catch (_) {
      // Deleting a corrupt artifact is best effort; the hash mismatch is the
      // error the user needs to see.
    }
  }
}

/// 目标平台可安装的安装包后缀（web 没有本地安装包，返回 null）。
String? updateArtifactExtension(String platform) => switch (platform) {
  'android' => '.apk',
  'windows' => '.exe',
  'linux' => '.AppImage',
  'macos' => '.dmg',
  _ => null,
};

/// 下载后保存的文件名。
///
/// 文件名来自清单里下载 URL 的最后一段（GitHub 资产 URL 就带着真实文件名），
/// 但那是外部输入：只取最后一段、剥掉路径分隔符与控制字符、干掉 `..`，
/// 再强制成该平台能安装的后缀（windows `.exe` / linux `.AppImage` /
/// android `.apk` / macos `.dmg`），所以 `../../etc/passwd` 这类地址
/// 只会留下一个普通文件名。
String updateArtifactFileName(ReleaseArtifact release) {
  final segments = release.downloadUrl.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList(growable: false);
  final raw = segments.isEmpty ? '' : _safeFileName(segments.last);
  final extension = updateArtifactExtension(release.platform);
  if (raw.isEmpty) {
    final fallback = _safeFileName(release.version);
    if (fallback.isEmpty) return '';
    return 'omniconvert-$fallback${extension ?? ''}';
  }
  if (extension == null) return raw;
  final dot = raw.lastIndexOf('.');
  final stem = dot > 0 ? raw.substring(0, dot) : raw;
  final current = dot > 0 ? raw.substring(dot) : '';
  if (current.toLowerCase() == extension.toLowerCase()) return raw;
  final safeStem = stem.isEmpty ? 'omniconvert' : stem;
  return '$safeStem$extension';
}

String _safeFileName(String raw) {
  var value = raw;
  try {
    value = Uri.decodeComponent(value);
  } catch (_) {
    // A malformed escape sequence is not worth failing over; sanitise as-is.
  }
  value = value
      // Path separators, Windows-reserved characters and control characters.
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F\x7F]'), '')
      // No traversal, no hidden ".file" names.
      .replaceAll('..', '')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  if (value.length > 120) {
    final dot = value.lastIndexOf('.');
    final suffix = dot > 0 && value.length - dot <= 16 ? value.substring(dot) : '';
    value = '${value.substring(0, 120 - suffix.length)}$suffix';
  }
  return value;
}

class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
}

/// The manifest itself is unusable (missing/invalid hash, non HTTPS URL).
class UpdateManifestException implements Exception {
  const UpdateManifestException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The transfer itself failed (HTTP status, redirect loop, ...).
class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The downloaded bytes do not match the hash promised by the manifest.
class UpdateSha256Mismatch implements Exception {
  const UpdateSha256Mismatch({required this.expected, required this.actual});

  final String expected;
  final String actual;

  String get message =>
      '下载的更新包校验失败（SHA-256 不匹配），文件已删除，请重试。';

  @override
  String toString() => message;
}

class _DigestCollector implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}