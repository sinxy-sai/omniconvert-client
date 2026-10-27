import '../../src/rust/api.dart' as rust;
import 'dart:io';
import 'dart:typed_data';
import 'tool_runner.dart';

class NativeToolRunner implements ToolRunner {
  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    final outputPath = request.outputPath.contains(RegExp(r'[\\/]'))
        ? request.outputPath
        : '${Directory.systemTemp.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}-${request.outputPath}';
    onProgress?.call(const ToolProgress(stage: 'validating', progress: 0));
    final result = await rust.runImageTool(
      toolId: request.toolId,
      inputPath: request.inputPath,
      outputPath: outputPath,
      options: request.options,
      maxBytes: BigInt.from(request.maxBytes),
    );
    if (!result.success) {
      throw ToolRunException(ToolRunFailure(
        code: result.errorCode,
        message: result.errorMessage,
        retryable: result.errorCode == 'Internal' || result.errorCode == 'ConverterFailed',
      ));
    }
    onProgress?.call(const ToolProgress(stage: 'completed', progress: 1));
    final outputFile = File(result.outputPath);
    final outputData = await outputFile.exists() ? await outputFile.readAsBytes() : null;
    return ToolRunResult(
      outputPath: result.outputPath,
      inputBytes: result.inputBytes.toInt(),
      outputBytes: result.outputBytes.toInt(),
      metadata: {
        'width': '${result.width}',
        'height': '${result.height}',
      },
      outputBytesData: outputData == null ? null : Uint8List.fromList(outputData),
    );
  }
}
