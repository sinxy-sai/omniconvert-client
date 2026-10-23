import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/updates/android_installer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('site.sinxysai.omniconvert/updates');

  test('passes a verified APK request to Android', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await const AndroidInstaller(channel: channel)
        .installVerifiedApk('/private/update.apk', 'A' * 64);
    expect(calls.single.method, 'installVerifiedApk');
    expect((calls.single.arguments as Map)['sha256'], 'a' * 64);
  });

  test('rejects malformed SHA-256 before invoking Android', () async {
    expect(
      () =>
          const AndroidInstaller(channel: channel)
              .installVerifiedApk('/private/update.apk', 'bad'),
      throwsFormatException,
    );
  });
}
