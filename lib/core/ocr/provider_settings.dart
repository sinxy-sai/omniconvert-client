import 'provider_settings_backend_stub.dart'
    if (dart.library.io) 'provider_settings_backend_io.dart'
    as backend;

class OcrProviderSettingsException implements Exception {
  const OcrProviderSettingsException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class OcrProviderSettingsBackend {
  Future<String?> readEndpoint();
  Future<void> writeEndpoint(String? endpoint);
}

class MemoryOcrProviderSettingsStore implements OcrProviderSettingsBackend {
  String? _endpoint;
  @override
  Future<String?> readEndpoint() async => _endpoint;
  @override
  Future<void> writeEndpoint(String? endpoint) async => _endpoint = endpoint;
}

class OcrProviderSettingsStore {
  OcrProviderSettingsStore([OcrProviderSettingsBackend? backendStore])
    : _backend = backendStore ?? backend.createBackend();
  final OcrProviderSettingsBackend _backend;

  Future<Uri?> loadCustomEndpoint() async {
    final value = await _backend.readEndpoint();
    return value == null ? null : Uri.parse(value);
  }

  Future<void> saveCustomEndpoint(
    Uri endpoint, {
    bool allowLocalHttp = false,
  }) async {
    final local = endpoint.host == 'localhost' || endpoint.host == '127.0.0.1';
    if (endpoint.scheme != 'https' && !(allowLocalHttp && local)) {
      throw const OcrProviderSettingsException('自建识别服务必须使用 HTTPS。');
    }
    if (endpoint.path.isNotEmpty && endpoint.path != '/') {
      throw const OcrProviderSettingsException('识别服务地址不能包含路径。');
    }
    await _backend.writeEndpoint(endpoint.toString());
  }

  Future<void> clearCustomEndpoint() => _backend.writeEndpoint(null);
}
