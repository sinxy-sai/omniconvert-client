import 'dart:io';
import 'dart:typed_data';

import '../../src/rust/api.dart' as rust;
import '../../src/rust/rust_initializer.dart';
import 'tool_runner.dart';
import 'backend_conversion_runner.dart';

class NativeToolRunner implements ToolRunner {
  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    if (request.toolId == 'docx_to_pdf' || request.toolId == 'mobi_to_pdf') {
      final bytes = request.inputBytes ?? await File(request.inputPath).readAsBytes();
      return const BackendConversionRunner().run(
        ToolRequest(
          toolId: request.toolId,
          inputPath: request.inputPath,
          outputPath: request.outputPath,
          options: request.options,
          maxBytes: request.maxBytes,
          inputBytes: bytes,
        ),
        onProgress: onProgress,
      );
    }
    File? temporaryInput;
    var inputPath = request.inputPath;
    if (request.inputBytes != null && !File(inputPath).existsSync()) {
      final extension = inputPath.split(RegExp(r'[\\/]')).last.split('.').last;
      final suffix = extension.isEmpty ? 'bin' : extension;
      temporaryInput = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'omniconvert-input-${DateTime.now().microsecondsSinceEpoch}.$suffix',
      );
      await temporaryInput.writeAsBytes(request.inputBytes!, flush: true);
      inputPath = temporaryInput.path;
    }
    final outputPath = request.outputPath.contains(RegExp(r'[\\/]'))
        ? request.outputPath
        : '${Directory.systemTemp.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}-${request.outputPath}';
    try {
      try {
        await initializeRust();
      } catch (error) {
        throw ToolRunException(
          ToolRunFailure(
            code: 'NativeCoreUnavailable',
            message: '本地处理核心无法加载：$error',
          ),
        );
      }
      onProgress?.call(const ToolProgress(stage: 'validating', progress: 0));
      final result = await rust.runImageTool(
        toolId: request.toolId,
        inputPath: inputPath,
        outputPath: outputPath,
        options: request.options,
        maxBytes: BigInt.from(request.maxBytes),
      );
      if (!result.success) {
        throw ToolRunException(
          ToolRunFailure(code: result.errorCode, message: result.errorMessage),
        );
      }
      onProgress?.call(const ToolProgress(stage: 'completed', progress: 1));
      final outputFile = File(result.outputPath);
      final outputData = await outputFile.exists()
          ? await outputFile.readAsBytes()
          : null;
      return ToolRunResult(
        outputPath: result.outputPath,
        inputBytes: result.inputBytes.toInt(),
        outputBytes: result.outputBytes.toInt(),
        metadata: {'width': '${result.width}', 'height': '${result.height}'},
        outputBytesData: outputData == null
            ? null
            : Uint8List.fromList(outputData),
      );
    } finally {
      if (temporaryInput != null) {
        try {
          await temporaryInput.delete();
        } on FileSystemException {
          // Best effort cleanup of the fallback input.
        }
      }
    }
  }


}
