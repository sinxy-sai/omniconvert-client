import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:omniconvert/core/tools/tool_runner.dart';
import 'package:omniconvert/core/tools/tool_runner_factory_web.dart';

/// A 4x3 test image with an opaque red pixel and a semi transparent pixel, so
/// alpha flattening (PNG -> JPEG) has something to actually flatten.
Uint8List sourcePng() {
  final source = image.Image(width: 4, height: 3);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      source.setPixelRgba(x, y, 255, 0, 0, 255);
    }
  }
  source.setPixelRgba(1, 1, 0, 0, 255, 128);
  return Uint8List.fromList(image.encodePng(source));
}

Uint8List sourceJpeg() {
  final source = image.Image(width: 4, height: 3);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      source.setPixelRgba(x, y, 0, 0, 255, 255);
    }
  }
  return Uint8List.fromList(image.encodeJpg(source));
}

Future<ToolRunResult> run(String toolId, Uint8List bytes, String output) {
  return createToolRunner().run(
    ToolRequest(
      toolId: toolId,
      inputPath: 'input.bin',
      outputPath: output,
      inputBytes: bytes,
      options: const {'quality': '80'},
    ),
  );
}

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
    final result = await runner.run(
      ToolRequest(
        toolId: 'png_to_jpeg',
        inputPath: 'photo.png',
        outputPath: 'photo.jpg',
        inputBytes: sourcePng(),
      ),
      onProgress: progress.add,
    );

    expect(result.outputBytesData, isNotEmpty);
    expect(result.outputPath, 'photo.jpg');
    expect(progress.first.stage, 'decoding');
    expect(progress.last.progress, 1);
    // JPEG SOI marker.
    expect(result.outputBytesData!.sublist(0, 3), [0xff, 0xd8, 0xff]);
  });

  test('web runner converts JPEG to PNG (previously unsupported)', () async {
    final result = await run('jpg_to_png', sourceJpeg(), 'photo.png');

    expect(result.outputBytesData, isNotEmpty);
    expect(
      result.outputBytesData!.sublist(0, 8),
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    );
    final decoded = image.decodePng(result.outputBytesData!);
    expect(decoded, isNotNull);
    expect(decoded!.width, 4);
    expect(decoded.height, 3);
  });

  test('web runner compresses JPEG input and reports the smaller payload', () async {
    final input = sourceJpeg();
    final result = await run('compress_image', input, 'photo.jpg');

    expect(result.outputBytesData, isNotEmpty);
    expect(result.inputBytes, input.length);
    expect(result.outputBytes, result.outputBytesData!.length);
    expect(result.outputBytesData!.sublist(0, 3), [0xff, 0xd8, 0xff]);
  });

  test('web runner wraps a PNG into a PDF document', () async {
    final result = await run('image_to_pdf', sourcePng(), 'photo.pdf');

    expect(result.outputBytesData, isNotEmpty);
    expect(
      String.fromCharCodes(result.outputBytesData!.sublist(0, 5)),
      '%PDF-',
    );
  });

  test('web runner rejects undecodable input with InvalidInput', () async {
    expect(
      () => run('png_to_jpeg', Uint8List.fromList([1, 2, 3, 4]), 'x.jpg'),
      throwsA(
        isA<ToolRunException>().having(
          (error) => error.failure.code,
          'code',
          'InvalidInput',
        ),
      ),
    );
  });
}