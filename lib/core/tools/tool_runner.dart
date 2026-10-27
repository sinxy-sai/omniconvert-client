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
  const ToolRunFailure({required this.code, required this.message});

  final String code;
  final String message;
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
