import 'dart:convert';

class ReleaseArtifact {
  const ReleaseArtifact({
    required this.platform,
    required this.arch,
    required this.version,
    required this.minimumSupportedVersion,
    required this.downloadUrl,
    required this.sha256,
    required this.releaseNotes,
  });
  final String platform;
  final String arch;
  final String version;
  final String minimumSupportedVersion;
  final Uri downloadUrl;
  final String sha256;
  final String releaseNotes;
}

class ReleaseManifest {
  const ReleaseManifest(this.releases);
  final List<ReleaseArtifact> releases;

  factory ReleaseManifest.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded['releases'] is! List) {
      throw const FormatException('manifest must contain releases');
    }
    final releases = (decoded['releases'] as List)
        .map((raw) {
          if (raw is! Map) {
            throw const FormatException('release must be an object');
          }
          final platform = raw['platform'];
          final arch = raw['arch'];
          final version = raw['version'];
          final minimum = raw['minimumSupportedVersion'];
          final url = raw['downloadUrl'];
          final hash = raw['sha256'];
          if ([
            platform,
            arch,
            version,
            minimum,
            url,
            hash,
            raw['releaseNotes'],
          ].any((v) => v is! String))
            throw const FormatException('release fields are invalid');
          }
          if (!const {
                'android',
                'web',
                'windows',
                'linux',
                'macos',
              }.contains(platform) ||
              arch == 'unknown')
            throw const FormatException('unsupported release target');
          }
          final parsedUrl = Uri.tryParse(url as String);
          if (parsedUrl == null || parsedUrl.scheme != 'https') {
            throw const FormatException('downloadUrl must use HTTPS');
          }
          if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hash as String)) {
            throw const FormatException('sha256 is invalid');
          }
          return ReleaseArtifact(
            platform: platform as String,
            arch: arch as String,
            version: version as String,
            minimumSupportedVersion: minimum as String,
            downloadUrl: parsedUrl,
            sha256: hash,
            releaseNotes: raw['releaseNotes'] as String,
          );
        })
        .toList(growable: false);
    return ReleaseManifest(releases);
  }
}
