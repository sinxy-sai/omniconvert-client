import 'dart:typed_data';

class ToolRequest {
  const ToolRequest({
    required this.toolId,
    required this.inputPath,
    required this.outputPath,
    this.options = const {},
    this.maxBytes = 64 * 1024 * 1024,
    this.inputBytes,
  });

  final String toolId;
  final String inputPath;
  final String outputPath;
  final Map<String, String> options;
  final int maxBytes;
  final Uint8List? inputBytes;

  @override
  bool operator ==(Object other) =>
      other is ToolRequest &&
      toolId == other.toolId &&
      inputPath == other.inputPath &&
      outputPath == other.outputPath &&
      maxBytes == other.maxBytes &&
      _bytesEqual(inputBytes, other.inputBytes) &&
      _mapsEqual(options, other.options);

  @override
  int get hashCode => Object.hash(toolId, inputPath, outputPath, maxBytes);
}

bool _bytesEqual(Uint8List? left, Uint8List? right) {
  if (left == null || right == null) return left == right;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

class ToolProgress {
  const ToolProgress({required this.stage, required this.progress});

  final String stage;
  final double progress;
}

class ToolRunResult {
  const ToolRunResult({
    required this.outputPath,
    required this.inputBytes,
    required this.outputBytes,
    this.metadata = const {},
    this.outputBytesData,
  });

  final String outputPath;
  final int inputBytes;
  final int outputBytes;
  final Map<String, String> metadata;
  final Uint8List? outputBytesData;
}

class ToolRunFailure {
  const ToolRunFailure({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final String code;
  final String message;
  final bool retryable;
}

class ToolRunException implements Exception {
  const ToolRunException(this.failure);

  final ToolRunFailure failure;
}

abstract interface class ToolRunner {
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  });
}
