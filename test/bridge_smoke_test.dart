import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/src/rust/api.dart';
import 'package:omniconvert/src/rust/frb_generated.dart';

void main() {
  test('Dart calls the Rust health check', () async {
    final fileName = switch (Platform.operatingSystem) {
      'windows' => 'omniconvert_core.dll',
      'macos' => 'libomniconvert_core.dylib',
      _ => 'libomniconvert_core.so',
    };
    final libraryPath = File('rust/target/debug/$fileName').absolute.path;
    expect(File(libraryPath).existsSync(), isTrue,
        reason: 'Run cargo build --manifest-path rust/Cargo.toml first.');

    await RustLib.init(externalLibrary: ExternalLibrary.open(libraryPath));
    try {
      expect(await healthCheck(), 'omniconvert-core-ok');

      final directory = await Directory.systemTemp.createTemp('omniconvert-bridge-');
      try {
        final input = File('test/fixtures/pixel.png').absolute;
        final output = File('${directory.path}/pixel.jpg');
        final outcome = await runImageTool(
          toolId: 'png_to_jpeg',
          inputPath: input.path,
          outputPath: output.path,
          options: const {'quality': '90'},
          maxBytes: BigInt.from(1024 * 1024),
        );
        expect(outcome.success, isTrue, reason: outcome.errorMessage);
        expect(outcome.width, 2);
        expect(outcome.height, 1);
        expect(outcome.outputBytes, greaterThan(BigInt.zero));
        expect(await output.exists(), isTrue);
        expect((await output.readAsBytes()).take(2), [0xff, 0xd8]);
      } finally {
        await directory.delete(recursive: true);
      }
    } finally {
      RustLib.dispose();
    }
  });
}
