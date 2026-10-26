class OcrCapabilities {
  const OcrCapabilities({
    required this.protocolVersion,
    required this.modes,
    required this.maxBytes,
    required this.maxTimeoutSeconds,
  });
  final String protocolVersion;
  final List<String> modes;
  final int maxBytes;
  final int maxTimeoutSeconds;
}

class OcrResult {
  const OcrResult({
    required this.requestId,
    required this.latex,
    required this.modelVersion,
    required this.warnings,
  });
  final String requestId;
  final String latex;
  final String modelVersion;
  final List<String> warnings;
}

class OcrProviderException implements Exception {
  const OcrProviderException(
    this.code,
    this.message, {
    this.retryable = false,
    this.requestId,
  });
  final String code;
  final String message;
  final bool retryable;
  final String? requestId;
  @override
  String toString() => '$code: $message';
}

abstract interface class OcrProvider {
  Future<OcrCapabilities> capabilities();
  Future<OcrResult> recognize(
    List<int> image, {
    required String mode,
    required String idempotencyKey,
    Duration timeout = const Duration(seconds: 20),
  });
}
