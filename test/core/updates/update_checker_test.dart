import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/updates/update_checker.dart';

String manifest({
  String version = '1.2.0',
  String minimum = '1.0.0',
  String url = 'https://example.com/app.apk',
}) =>
    '{"releases":[{"platform":"android","arch":"arm64-v8a","version":"$version","minimumSupportedVersion":"$minimum","downloadUrl":"$url","sha256":"${'a' * 64}","releaseNotes":"notes"}]}';

void main() {
  test('reports current and available versions', () async {
    final checker = UpdateChecker(() async => manifest());
    expect(
      (await checker.check('1.2.0', 'android', 'arm64-v8a')).state,
      UpdateState.current,
    );
    expect(
      (await checker.check('1.1.0', 'android', 'arm64-v8a')).state,
      UpdateState.available,
    );
  });
  test('blocks below minimum and ignores wrong platform', () async {
    final checker = UpdateChecker(() async => manifest(minimum: '1.1.0'));
    expect(
      (await checker.check('1.0.0', 'android', 'arm64-v8a')).state,
      UpdateState.required,
    );
    expect(
      (await checker.check('1.0.0', 'windows', 'x64')).state,
      UpdateState.current,
    );
  });
  test('rejects invalid HTTPS manifest', () async {
    final checker = UpdateChecker(
      () async => manifest(url: 'http://example.com/app.apk'),
    );
    expect(
      (await checker.check('1.0.0', 'android', 'arm64-v8a')).state,
      UpdateState.invalidManifest,
    );
  });
}
