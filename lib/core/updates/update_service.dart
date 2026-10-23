import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'update_checker.dart';

const releaseManifestUrl = 'https://www.sinxysai.site/releases/latest.json';

class UpdateService {
  const UpdateService({this.client, MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('site.sinxysai.omniconvert/updates');

  final http.Client? client;
  final MethodChannel _channel;

  Future<UpdateResult> check(String currentVersion) async {
    final target = await _target();
    if (target == null) return const UpdateResult(UpdateState.current);
    final httpClient = client ?? http.Client();
    try {
      return await UpdateChecker(() async {
        final response = await httpClient.get(Uri.parse(releaseManifestUrl));
        if (response.statusCode != 200) {
          throw StateError(
            'Release service returned HTTP ${response.statusCode}',
          );
        }
        return response.body;
      }).check(currentVersion, target.$1, target.$2);
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<(String, String)?> _target() async {
    if (kIsWeb) return ('web', 'all');
    if (defaultTargetPlatform == TargetPlatform.android) {
      final abi = await _channel.invokeMethod<String>('deviceArch');
      if (abi == null ||
          !const {'arm64-v8a', 'armeabi-v7a', 'x86_64'}.contains(abi)) {
        throw const FormatException('Unsupported Android architecture');
      }
      return ('android', abi);
    }
    return null;
  }
}
