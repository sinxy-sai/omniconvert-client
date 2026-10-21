import '../../src/rust/api.dart' as rust;
import 'tool_runner.dart';

class NativeToolRunner implements ToolRunner {
  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    onProgress?.call(const ToolProgress(stage: 'validating', progress: 0));
    final result = await rust.runImageTool(
      toolId: request.toolId,
      inputPath: request.inputPath,
      outputPath: request.outputPath,
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
    return ToolRunResult(
      outputPath: result.outputPath,
      inputBytes: result.inputBytes.toInt(),
      outputBytes: result.outputBytes.toInt(),
      metadata: {
        'width': '${result.width}',
        'height': '${result.height}',
      },
    );
  }
}
