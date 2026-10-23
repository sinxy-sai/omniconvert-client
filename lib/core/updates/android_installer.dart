import 'package:flutter/services.dart';

/// Hands a previously downloaded APK to Android after native verification.
/// Android verifies the file hash, package name, signing certificate and
/// private file location before opening the system confirmation screen.
class AndroidInstaller {
  const AndroidInstaller({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('site.sinxysai.omniconvert/updates');

  final MethodChannel _channel;

  Future<void> installVerifiedApk(String path, String expectedSha256) async {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(expectedSha256)) {
      throw const FormatException(
        'Expected SHA-256 must be 64 hexadecimal characters',
      );
    }
    await _channel.invokeMethod<void>('installVerifiedApk', {
      'path': path,
      'sha256': expectedSha256.toLowerCase(),
    });
  }
}
