import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:omniconvert/core/tools/dart_tool_runner.dart';
import 'package:omniconvert/core/tools/output_file_name.dart';
import 'package:omniconvert/core/tools/tool_runner.dart';

/// Contract test shared with the browser smoke test.
///
/// `tool/e2e/web_smoke.js` drives the real UI with exactly these two samples and
/// asserts the same five outcomes. Keeping byte-for-byte identical fixtures in
/// Dart means a red e2e run can be attributed immediately:
///
/// * this test green + e2e red  -> the UI / file-picker / download layer broke;
/// * this test red              -> the engine itself regressed.
///
/// **If you change a sample here, change the identical base64 in
/// `tool/e2e/web_smoke.js`.** Both samples are machine generated and verified
/// to decode with `package:image 4.5.4`:
/// * PNG: 8x8 RGBA, the whole top-right 4x4 quadrant is fully transparent
///   (alpha 0), the rest is opaque `rgb(220,40,60)`. 93 bytes.
/// * JPEG: 8x8 baseline, 4:4:4 (no chroma subsampling), quality 90: blue
///   `rgb(30,120,210)` with a yellow `rgb(240,230,20)` bottom-right quadrant.
///   367 bytes. Generated once with Pillow and pinned here on purpose.

/// 8x8 RGBA PNG with a fully transparent top-right quadrant.
const String kPngSampleBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJElEQVR42mO8o2HznwEJqNw4wojMZ2IgAChXwIjuBupbQVABACWfBk51skGuAAAAAElFTkSuQmCC';

/// 8x8 baseline 4:4:4 JPEG.
const String kJpegSampleBase64 =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAAIAAgDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EACEQAAAFAgcAAAAAAAAAAAAAAAcREhMVAAIUFyUxRGFi/8QAFQEBAQAAAAAAAAAAAAAAAAAABgf/xAAmEQACAQEECwAAAAAAAAAAAAAREhMGAAEHYQIUFRchIyRBQkNi/9oADAMBAAIRAxEAPwBAfB/NeX1eLwDPGecWv3aRI73pjiZiZu61Po555PYionxpkvkB3PCTU7Tu3peaiL4kk53AC3//2Q==';

Uint8List get pngSample => Uint8List.fromList(base64Decode(kPngSampleBase64));
Uint8List get jpegSample => Uint8List.fromList(base64Decode(kJpegSampleBase64));

const List<int> kPngMagic = <int>[0x89, 0x50, 0x4e, 0x47];
const List<int> kJpegMagic = <int>[0xff, 0xd8, 0xff];
const int kSampleSize = 8;

Future<ToolRunResult> _run(
  String toolId,
  Uint8List bytes, {
  String outputPath = 'out.bin',
  Map<String, String> options = const {},
}) => DartToolRunner().run(
  ToolRequest(
    toolId: toolId,
    inputPath: 'sample.bin',
    outputPath: outputPath,
    inputBytes: bytes,
    maxBytes: 8 * 1024 * 1024,
    options: options,
  ),
);

void main() {
  group('the e2e fixtures are valid for the engine', () {
    test('the 8x8 PNG decodes and really carries a transparent quadrant', () {
      final decoded = image.decodeImage(pngSample);
      expect(decoded, isNotNull, reason: 'e2e PNG sample must decode');
      expect(decoded!.width, kSampleSize);
      expect(decoded.height, kSampleSize);
      // Top-right quadrant is transparent, bottom-left is opaque.
      expect(decoded.getPixel(7, 0).a, 0,
          reason: 'PNG -> JPEG must exercise alpha flattening');
      expect(decoded.getPixel(0, 7).a, 255);
    });

    test('the 8x8 JPEG sample decodes (not treated as corrupt)', () {
      final decoded = image.decodeImage(jpegSample);
      expect(decoded, isNotNull, reason: 'e2e JPEG sample must decode');
      expect(decoded!.width, kSampleSize);
      expect(decoded.height, kSampleSize);
    });

    test('the base64 fixtures are well formed (a truncated sample would be '
        'silently accepted by Node but maps to InvalidInput here)', () {
      expect(pngSample.length, 93);
      expect(jpegSample.length, 367);
      expect(pngSample.sublist(0, 4), kPngMagic);
      expect(jpegSample.sublist(0, 3), kJpegMagic);
    });
  });

  group('browser smoke test contract', () {
    test('png_to_jpeg -> JPEG bytes, 8x8, .jpg name', () async {
      final result = await _run(
        'png_to_jpeg',
        pngSample,
        outputPath: outputFileNameFor(
          toolId: 'png_to_jpeg',
          inputFileName: 'sample.png',
        ),
      );

      final out = result.outputBytesData!;
      expect(out.sublist(0, 3), kJpegMagic);
      expect(result.metadata['width'], '$kSampleSize');
      expect(result.metadata['height'], '$kSampleSize');
      expect(result.outputPath, endsWith('.jpg'));
      // The transparent quadrant must be flattened to white, not black.
      final flat = image.decodeJpg(out)!.getPixel(7, 0);
      expect(flat.r, greaterThan(230));
      expect(flat.g, greaterThan(230));
      expect(flat.b, greaterThan(230));
    });

    test('jpg_to_png -> PNG bytes, 8x8, .png name', () async {
      final result = await _run(
        'jpg_to_png',
        jpegSample,
        outputPath: outputFileNameFor(
          toolId: 'jpg_to_png',
          inputFileName: 'sample.jpg',
        ),
      );

      final out = result.outputBytesData!;
      expect(out.sublist(0, 4), kPngMagic);
      expect(image.decodePng(out)!.width, kSampleSize);
      expect(result.outputPath, endsWith('.png'));
    });

    test('compress_image keeps PNG as PNG', () async {
      final result = await _run('compress_image', pngSample);

      final out = result.outputBytesData!;
      expect(out.sublist(0, 4), kPngMagic,
          reason: 'the shipped regression: PNG must not become JPEG');
      expect(out.sublist(0, 3), isNot(kJpegMagic));
      expect(image.decodePng(out), isNotNull);
      expect(
        outputFileNameFor(
          toolId: 'compress_image',
          inputFileName: 'sample.png',
        ),
        'sample.png',
      );
    });

    test('compress_image keeps JPEG as JPEG', () async {
      final result = await _run('compress_image', jpegSample);

      final out = result.outputBytesData!;
      expect(out.sublist(0, 3), kJpegMagic);
      expect(image.decodeJpg(out), isNotNull);
      expect(
        outputFileNameFor(
          toolId: 'compress_image',
          inputFileName: 'sample.jpg',
        ),
        'sample.jpg',
      );
    });

    test('image_to_pdf -> PDF bytes with an 8x8 page', () async {
      final result = await _run('image_to_pdf', pngSample);

      final out = result.outputBytesData!;
      expect(String.fromCharCodes(out.sublist(0, 5)), '%PDF-');
      final text = String.fromCharCodes(out);
      final box = RegExp(
        r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)',
      ).firstMatch(text);
      expect(box, isNotNull);
      expect(double.parse(box!.group(3)!), closeTo(kSampleSize, 0.01));
      expect(double.parse(box.group(4)!), closeTo(kSampleSize, 0.01));
      expect(
        outputFileNameFor(toolId: 'image_to_pdf', inputFileName: 'sample.png'),
        'sample.pdf',
      );
    });

    test('an empty sample fails loudly instead of producing bytes', () {
      expect(
        () => _run('png_to_jpeg', Uint8List(0)),
        throwsA(
          isA<ToolRunException>().having(
            (error) => error.failure.code,
            'code',
            'InvalidInput',
          ),
        ),
      );
    });
  });
}