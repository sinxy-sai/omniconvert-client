import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:omniconvert/core/tools/tool_runner.dart';
import 'package:omniconvert/core/tools/tool_runner_factory_web.dart';

void main() {
  test('web runner rejects path-only requests with a typed local input error', () async {
    expect(
      () => createToolRunner().run(const ToolRequest(
        toolId: 'png_to_jpeg',
        inputPath: 'photo.png',
        outputPath: 'photo.jpg',
      )),
      throwsA(
        isA<ToolRunException>().having(
          (error) => error.failure.code,
          'code',
          'InputBytesRequired',
        ),
      ),
    );
  });

  test('web runner exposes in-memory output for PNG to JPEG', () async {
    final runner = createToolRunner();
    final progress = <ToolProgress>[];
    final source = image.Image(width: 2, height: 1);
    source.setPixelRgba(0, 0, 255, 0, 0, 255);
    source.setPixelRgba(1, 0, 0, 255, 0, 128);
    final result = await runner.run(
      ToolRequest(
        toolId: 'png_to_jpeg',
        inputPath: 'photo.png',
        outputPath: 'photo.jpg',
        inputBytes: Uint8List.fromList(image.encodePng(source)),
      ),
      onProgress: progress.add,
    );

    expect(result.outputBytesData, isNotEmpty);
    expect(result.outputPath, 'photo.jpg');
    expect(progress.first.stage, 'decoding');
    expect(progress.last.progress, 1);
  });
}
