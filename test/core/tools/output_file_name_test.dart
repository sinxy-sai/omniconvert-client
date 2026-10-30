import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tools/output_file_name.dart';

void main() {
  group('outputFileNameFor reads the single source registry', () {
    test('fixed output extension replaces the input extension', () {
      expect(
        outputFileNameFor(toolId: 'png_to_jpeg', inputFileName: 'photo.png'),
        'photo.jpg',
      );
      expect(
        outputFileNameFor(toolId: 'jpg_to_png', inputFileName: 'photo.jpeg'),
        'photo.png',
      );
      expect(
        outputFileNameFor(toolId: 'image_to_pdf', inputFileName: 'scan.JPG'),
        'scan.pdf',
      );
      expect(
        outputFileNameFor(toolId: 'docx_to_pdf', inputFileName: 'report.docx'),
        'report.pdf',
      );
    });

    test('keeps the format for compress_image and normalises jpeg to jpg', () {
      expect(
        outputFileNameFor(toolId: 'compress_image', inputFileName: 'photo.png'),
        'photo.png',
      );
      expect(
        outputFileNameFor(toolId: 'compress_image', inputFileName: 'photo.jpeg'),
        'photo.jpg',
      );
      expect(
        outputFileNameFor(toolId: 'compress_image', inputFileName: 'photo.JPG'),
        'photo.jpg',
      );
    });

    test('strips directories and keeps multi dot file names', () {
      expect(
        outputFileNameFor(
          toolId: 'png_to_jpeg',
          inputFileName: r'C:\Pictures\holiday\beach.2024.png',
        ),
        'beach.2024.jpg',
      );
      expect(
        outputFileNameFor(toolId: 'image_to_pdf', inputFileName: '/tmp/a/b/c.png'),
        'c.pdf',
      );
    });

    test('appends the extension when the input has none', () {
      expect(
        outputFileNameFor(toolId: 'image_to_pdf', inputFileName: 'scan'),
        'scan.pdf',
      );
      expect(
        outputFileNameFor(toolId: 'png_to_jpeg', inputFileName: 'photo.'),
        'photo.jpg',
      );
    });

    test('format preserving tools cannot invent an extension', () {
      expect(
        outputFileNameFor(toolId: 'compress_image', inputFileName: 'blob'),
        'blob',
      );
    });

    test('unknown tools are left untouched instead of guessing', () {
      expect(
        outputFileNameFor(toolId: 'mystery_tool', inputFileName: 'data.bin'),
        'data.bin',
      );
      expect(outputFileNameFor(toolId: 'mystery_tool', inputFileName: 'data'), 'data');
    });

    test('is pure: no IO, stable for repeated calls', () {
      expect(
        outputFileNameFor(toolId: 'jpg_to_png', inputFileName: 'a.jpg'),
        outputFileNameFor(toolId: 'jpg_to_png', inputFileName: 'a.jpg'),
      );
    });
  });

  group('legacy defaultOutputFileName still works', () {
    test('uses the input base name with the target extension', () {
      expect(defaultOutputFileName(r'C:\Pictures\photo.png', 'jpg'), 'photo.jpg');
      expect(defaultOutputFileName('formula', 'pdf'), 'formula.pdf');
    });
  });
}