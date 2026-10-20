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
    } finally {
      RustLib.dispose();
    }
  });
}
