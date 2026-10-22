import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pw;

import 'tool_runner.dart';

class WebImageToolRunner implements ToolRunner {
  bool _cancelled = false;

  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    final input = request.inputBytes;
    if (input == null) {
      throw const ToolRunException(ToolRunFailure(
        code: 'InputBytesRequired',
        message: '浏览器本地处理需要以内存字节提供输入文件。',
        retryable: false,
      ));
    }
    if (input.length > request.maxBytes) {
      throw const ToolRunException(ToolRunFailure(
        code: 'InputTooLarge',
        message: '输入文件超过大小限制。',
        retryable: false,
      ));
    }
    _cancelled = false;
    onProgress?.call(const ToolProgress(stage: 'decoding', progress: 0));
    final decoded = image.decodeImage(input);
    if (decoded == null) {
      throw const ToolRunException(ToolRunFailure(
        code: 'InvalidInput',
        message: '无法识别图片数据。',
        retryable: false,
      ));
    }
    if (_cancelled) throw _cancelledError;
    onProgress?.call(const ToolProgress(stage: 'encoding', progress: .5));
    final output = switch (request.toolId) {
      'png_to_jpeg' => image.encodeJpg(
          _flattenAlpha(decoded),
          quality: _quality(request),
        ),
      'compress_image' => image.encodeJpg(decoded, quality: _quality(request)),
      'image_to_pdf' => await _toPdf(input),
      _ => throw const ToolRunException(ToolRunFailure(
          code: 'UnsupportedTool',
          message: '浏览器暂不支持该工具。',
          retryable: false,
        )),
    };
    if (_cancelled) throw _cancelledError;
    onProgress?.call(const ToolProgress(stage: 'completed', progress: 1));
    return ToolRunResult(
      outputPath: request.outputPath,
      inputBytes: input.length,
      outputBytes: output.length,
      outputBytesData: Uint8List.fromList(output),
      metadata: {'width': '${decoded.width}', 'height': '${decoded.height}'},
    );
  }

  image.Image _flattenAlpha(image.Image source) {
    final result = image.Image(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final alpha = pixel.a / 255;
        result.setPixelRgb(
          x,
          y,
          (pixel.r * alpha + 255 * (1 - alpha)).round(),
          (pixel.g * alpha + 255 * (1 - alpha)).round(),
          (pixel.b * alpha + 255 * (1 - alpha)).round(),
        );
      }
    }
    return result;
  }

  int _quality(ToolRequest request) =>
      int.tryParse(request.options['quality'] ?? '')?.clamp(1, 100) ?? 85;

  Future<Uint8List> _toPdf(Uint8List input) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(input)))),
    );
    return Uint8List.fromList(await document.save());
  }

  static const _cancelledError = ToolRunException(ToolRunFailure(
    code: 'Cancelled',
    message: '任务已取消。',
    retryable: true,
  ));

  void cancel() => _cancelled = true;
}

ToolRunner createToolRunner() => WebImageToolRunner();
