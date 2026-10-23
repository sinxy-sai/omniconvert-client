import 'release_manifest.dart';

enum UpdateState { current, available, required, invalidManifest }

class UpdateResult {
  const UpdateResult(this.state, {this.release, this.error});
  final UpdateState state;
  final ReleaseArtifact? release;
  final Object? error;
}

typedef ManifestLoader = Future<String> Function();

class UpdateChecker {
  const UpdateChecker(this.loadManifest);
  final ManifestLoader loadManifest;

  Future<UpdateResult> check(
    String currentVersion,
    String platform,
    String arch,
  ) async {
    try {
      final manifest = ReleaseManifest.fromJson(await loadManifest());
      final candidates = manifest.releases
          .where((r) => r.platform == platform && r.arch == arch)
          .toList();
      if (candidates.isEmpty) return const UpdateResult(UpdateState.current);
      candidates.sort((a, b) => _compare(b.version, a.version));
      final release = candidates.first;
      final state =
          _compare(currentVersion, release.minimumSupportedVersion) < 0
          ? UpdateState.required
          : _compare(currentVersion, release.version) < 0
          ? UpdateState.available
          : UpdateState.current;
      return UpdateResult(state, release: release);
    } catch (error) {
      return UpdateResult(UpdateState.invalidManifest, error: error);
    }
  }

  static int _compare(String left, String right) {
    final a = left.split('.').map(int.parse).toList();
    final b = right.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final result = (a.length > i ? a[i] : 0).compareTo(
        b.length > i ? b[i] : 0,
      );
      if (result != 0) return result;
    }
    return 0;
  }
}
