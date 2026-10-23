import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ocr_provider.dart';

abstract class HttpOcrProvider implements OcrProvider {
  const HttpOcrProvider(this.baseUri, {http.Client? client}) : _client = client;
  final Uri baseUri;
  final http.Client? _client;
  http.Client get client => _client ?? http.Client();

  void validateEndpoint({bool allowLocalHttp = false}) {
    final local = baseUri.host == 'localhost' || baseUri.host == '127.0.0.1';
    if (baseUri.scheme != 'https' && !(allowLocalHttp && local))
      throw const OcrProviderException(
        'insecure_endpoint',
        'Provider endpoint must use HTTPS',
      );
  }

  @override
  Future<OcrCapabilities> capabilities() async {
    validateEndpoint();
    final response = await client.get(baseUri.resolve('/v1/capabilities'));
    if (response.statusCode != 200)
      throw OcrProviderException(
        'provider_unavailable',
        'Capabilities request failed',
        retryable: true,
      );
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OcrCapabilities(
        protocolVersion: json['protocolVersion'] as String,
        modes: (json['modes'] as List).cast<String>(),
        maxBytes: json['maxBytes'] as int,
        maxTimeoutSeconds: json['maxTimeoutSeconds'] as int,
      );
    } catch (_) {
      throw const OcrProviderException(
        'malformed_response',
        'Capabilities response is invalid',
      );
    }
  }

  Future<OcrResult> parseResult(http.Response response) async {
    if (response.statusCode != 200)
      throw OcrProviderException(
        'provider_error',
        'Recognition request failed',
        retryable: response.statusCode >= 500,
      );
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OcrResult(
        requestId: json['requestId'] as String,
        latex: json['latex'] as String,
        modelVersion: json['modelVersion'] as String,
        warnings: (json['warnings'] as List).cast<String>(),
      );
    } catch (_) {
      throw const OcrProviderException(
        'malformed_response',
        'Recognition response is invalid',
      );
    }
  }
}
