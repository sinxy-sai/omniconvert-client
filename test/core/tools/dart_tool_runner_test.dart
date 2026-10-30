import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:omniconvert/core/tools/dart_tool_runner.dart';
import 'package:omniconvert/core/tools/tool_runner.dart';
import 'package:omniconvert/core/tools/tool_runner_factory_native.dart'
    as native_factory;
import 'package:omniconvert/core/tools/tool_runner_factory_web.dart'
    as web_factory;

const _pngMagic = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const _jpegMagic = <int>[0xff, 0xd8, 0xff];

/// 40x30 RGBA image; the left half is fully transparent when [transparent].
Uint8List sourcePng({bool transparent = false, int width = 40, int height = 30}) {
  final img = image.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = transparent && x < width ~/ 2 ? 0 : 255;
      img.setPixelRgba(x, y, 220, 40, 60, alpha);
    }
  }
  return Uint8List.fromList(image.encodePng(img));
}

Uint8List sourceJpeg({int width = 40, int height = 30}) {
  final img = image.Image(width: width, height: height, numChannels: 3);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      img.setPixelRgb(x, y, 20, 90, 200);
    }
  }
  return Uint8List.fromList(image.encodeJpg(img, quality: 92));
}

/// 160x160 deterministic high-entropy PNG, so zlib levels (and therefore the
/// preset mapping) actually change the output size.
Uint8List noisyPng() {
  final img = image.Image(width: 160, height: 160, numChannels: 3);
  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      img.setPixelRgb(x, y, (x * 37 + y * 11) % 256, (x * 7 + y * 53) % 256, (x ^ y) % 256);
    }
  }
  return Uint8List.fromList(image.encodePng(img, level: 1));
}

Future<ToolRunResult> runTool(
  String toolId,
  Uint8List bytes, {
  String outputPath = 'result.bin',
  Map<String, String> options = const {},
  int maxBytes = 8 * 1024 * 1024,
  List<ToolProgress>? progress,
}) {
  return DartToolRunner().run(
    ToolRequest(
      toolId: toolId,
      inputPath: 'input.bin',
      outputPath: outputPath,
      inputBytes: bytes,
      options: options,
      maxBytes: maxBytes,
    ),
    onProgress: progress?.add,
  );
}

Matcher throwsToolCode(String code) => throwsA(
  isA<ToolRunException>().having(
    (error) => error.failure.code,
    'code',
    code,
  ),
);

void main() {
  group('DartToolRunner is the single cross-platform engine', () {
    test('web and native factories return the same engine', () {
      expect(native_factory.createToolRunner(), isA<DartToolRunner>());
      expect(web_factory.createToolRunner(), isA<DartToolRunner>());
    });

    test('only the four image tools are handled in process', () {
      expect(kDartImageToolIds, {
        'png_to_jpeg',
        'jpg_to_png',
        'compress_image',
        'image_to_pdf',
      });
      expect(isDartImageTool('png_to_jpeg'), isTrue);
      expect(isDartImageTool('mobi_to_pdf'), isFalse);
    });
  });

  group('png_to_jpeg', () {
    test('produces a JPEG and flattens transparency to white', () async {
      final result = await runTool(
        'png_to_jpeg',
        sourcePng(transparent: true),
        outputPath: 'photo.jpg',
      );

      expect(result.outputBytesData, isNotNull);
      expect(result.outputBytesData!.sublist(0, 3), _jpegMagic);
      // On native a bare output name lands in the system temp dir.
      expect(result.outputPath, endsWith('photo.jpg'));
      expect(result.metadata['width'], '40');
      expect(result.metadata['height'], '30');

      final decoded = image.decodeJpg(result.outputBytesData!)!;
      // Left half was fully transparent -> must be white, never black/green.
      final flat = decoded.getPixel(2, 2);
      expect(flat.r, greaterThan(240));
      expect(flat.g, greaterThan(240));
      expect(flat.b, greaterThan(240));
    });

    test('honours the explicit quality option', () async {
      final result = await runTool(
        'png_to_jpeg',
        sourcePng(),
        options: const {'quality': '30'},
      );
      expect(result.outputBytesData!.sublist(0, 3), _jpegMagic);
    });
  });

  group('jpg_to_png', () {
    test('produces a PNG with the input dimensions', () async {
      final result = await runTool(
        'jpg_to_png',
        sourceJpeg(),
        outputPath: 'photo.png',
      );

      expect(result.outputBytesData!.sublist(0, 8), _pngMagic);
      final decoded = image.decodePng(result.outputBytesData!)!;
      expect(decoded.width, 40);
      expect(decoded.height, 30);
    });
  });

  group('compress_image keeps the input format', () {
    test('PNG in -> PNG out, transparency preserved', () async {
      final input = sourcePng(transparent: true);
      final result = await runTool(
        'compress_image',
        input,
        outputPath: 'photo.png',
        options: const {'preset': 'small'},
      );

      final output = result.outputBytesData!;
      expect(output.sublist(0, 8), _pngMagic,
          reason: 'compressing a PNG must never emit JPEG bytes');
      expect(result.inputBytes, input.length);
      expect(result.outputBytes, output.length);

      final decoded = image.decodePng(output)!;
      expect(decoded.numChannels, 4);
      expect(decoded.getPixel(1, 1).a, 0, reason: 'alpha must survive');
    });

    test('JPEG in -> JPEG out', () async {
      final input = sourceJpeg();
      final result = await runTool(
        'compress_image',
        input,
        outputPath: 'photo.jpg',
        options: const {'preset': 'balanced'},
      );

      expect(result.outputBytesData!.sublist(0, 3), _jpegMagic);
      final decoded = image.decodeJpg(result.outputBytesData!)!;
      expect(decoded.width, 40);
    });

    test('preset small is not larger than preset high', () async {
      final input = sourcePng(transparent: true);
      final high = await runTool(
        'compress_image',
        input,
        options: const {'preset': 'high'},
      );
      final small = await runTool(
        'compress_image',
        input,
        options: const {'preset': 'small'},
      );
      expect(small.outputBytes, lessThanOrEqualTo(high.outputBytes));
    });

    test('the control the user touched wins over the untouched default', () async {
      final input = noisyPng();
      // Explicit quality (max) must not be silently overridden by the default
      // preset, and it must not silently beat an explicit "small" preset.
      final smallPreset = await runTool(
        'compress_image',
        input,
        options: const {'preset': 'small'},
      );
      final maxQuality = await runTool(
        'compress_image',
        input,
        options: const {'quality': '100'},
      );

      expect(smallPreset.outputBytesData!.sublist(0, 8), _pngMagic);
      expect(maxQuality.outputBytesData!.sublist(0, 8), _pngMagic);
      expect(
        smallPreset.outputBytes,
        lessThanOrEqualTo(maxQuality.outputBytes),
        reason: 'explicit preset small should compress at least as hard '
            'as explicit quality 100',
      );
    });
  });

  group('image_to_pdf', () {
    test('layout=fit uses the image pixel size as the page size', () async {
      final result = await runTool(
        'image_to_pdf',
        sourcePng(width: 120, height: 90),
        outputPath: 'photo.pdf',
        options: const {'layout': 'fit'},
      );

      final bytes = result.outputBytesData!;
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      final box = _mediaBox(bytes);
      expect(box, isNotNull);
      expect(box![0], closeTo(0, 0.01));
      expect(box[1], closeTo(0, 0.01));
      expect(box[2], closeTo(120, 0.01), reason: 'page width == pixel width');
      expect(box[3], closeTo(90, 0.01), reason: 'page height == pixel height');
    });

    test('layout=a4 uses an A4 page so nothing is cropped', () async {
      final result = await runTool(
        'image_to_pdf',
        sourcePng(width: 600, height: 200),
        outputPath: 'photo.pdf',
        options: const {'layout': 'a4'},
      );

      final bytes = result.outputBytesData!;
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      final box = _mediaBox(bytes)!;
      // A4 = 21.0cm x 29.7cm = 595.28 x 841.89 PDF points.
      expect(box[2], closeTo(595.28, 0.5));
      expect(box[3], closeTo(841.89, 0.5));
    });

    test('accepts JPEG input and transparent PNG input', () async {
      final fromJpeg = await runTool(
        'image_to_pdf',
        sourceJpeg(),
        options: const {'layout': 'a4'},
      );
      final fromPng = await runTool(
        'image_to_pdf',
        sourcePng(transparent: true),
        options: const {'layout': 'fit'},
      );
      expect(String.fromCharCodes(fromJpeg.outputBytesData!.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(fromPng.outputBytesData!.sublist(0, 5)), '%PDF-');
    });
  });

  group('progress and cancellation contract', () {
    test('reports decoding -> encoding -> completed', () async {
      final progress = <ToolProgress>[];
      await runTool('png_to_jpeg', sourcePng(), progress: progress);

      expect(progress.map((p) => p.stage).toList(), [
        'decoding',
        'encoding',
        'completed',
      ]);
      expect(progress.map((p) => p.progress).toList(), [0.0, 0.5, 1.0]);
    });

    test('a cancelled runner writes nothing', () async {
      final directory = await Directory.systemTemp.createTemp('oc-cancel-');
      try {
        final runner = DartToolRunner();
        final target = '${directory.path}/out.jpg';
        // Cancel while the job is in flight, exactly like the UI cancel button.
        final pending = runner.run(
          ToolRequest(
            toolId: 'png_to_jpeg',
            inputPath: 'input.png',
            outputPath: target,
            inputBytes: sourcePng(),
          ),
        );
        runner.cancel();

        await expectLater(pending, throwsToolCode('Cancelled'));
        expect(
          directory.listSync().whereType<File>(),
          isEmpty,
          reason: 'cancelled runs must not leave partial files',
        );
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });

  group('failures use the canonical error taxonomy', () {
    test('input above the byte budget is InputTooLarge', () {
      return expectLater(
        runTool('png_to_jpeg', sourcePng(), maxBytes: 16),
        throwsToolCode('InputTooLarge'),
      );
    });

    test('corrupt bytes are InvalidInput', () {
      return expectLater(
        runTool('png_to_jpeg', Uint8List.fromList([1, 2, 3, 4])),
        throwsToolCode('InvalidInput'),
      );
    });

    test('an unknown tool is UnsupportedTool', () {
      return expectLater(
        runTool('not_a_tool', sourcePng()),
        throwsToolCode('UnsupportedTool'),
      );
    });

    test('a missing file is InvalidInput, not a crash', () {
      return expectLater(
        DartToolRunner().run(
          const ToolRequest(
            toolId: 'png_to_jpeg',
            inputPath: 'definitely-missing-input.png',
            outputPath: 'out.jpg',
          ),
        ),
        throwsToolCode('InvalidInput'),
      );
    });
  });

  group('native file pipeline', () {
    test('writes the output file to disk', () async {
      final directory = await Directory.systemTemp.createTemp('oc-write-');
      try {
        final target = '${directory.path}/nested/photo.jpg';
        final result = await runTool(
          'png_to_jpeg',
          sourcePng(),
          outputPath: target,
        );

        final file = File(target);
        expect(await file.exists(), isTrue);
        expect(result.outputPath, file.absolute.path);
        expect((await file.readAsBytes()).sublist(0, 3), _jpegMagic);
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });
}

/// Reads the first `/MediaBox [a b c d]` of a PDF as doubles.
List<double>? _mediaBox(Uint8List bytes) {
  final text = String.fromCharCodes(bytes);
  final match = RegExp(
    r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)',
  ).firstMatch(text);
  if (match == null) return null;
  return [
    for (var i = 1; i <= 4; i++) double.parse(match.group(i)!),
  ];
}