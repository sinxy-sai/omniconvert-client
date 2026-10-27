import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tools/output_file_name.dart';

void main() {
  test('uses the input base name with the target extension', () {
    expect(defaultOutputFileName(r'C:\Pictures\photo.png', 'jpg'), 'photo.jpg');
    expect(defaultOutputFileName('formula', 'pdf'), 'formula.pdf');
  });
}
