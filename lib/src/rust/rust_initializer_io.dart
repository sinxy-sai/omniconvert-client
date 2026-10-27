import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'frb_generated.dart';

Future<void>? _initialization;

Future<void> initializeRust() => _initialization ??= _loadRust();

Future<void> _loadRust() async {
  final libraryName = switch (Platform.operatingSystem) {
    'windows' => 'omniconvert_core.dll',
    'macos' => 'libomniconvert_core.dylib',
    _ => 'libomniconvert_core.so',
  };
  final candidates = [
    File('${Directory.current.path}${Platform.pathSeparator}$libraryName'),
    File(
      '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}$libraryName',
    ),
    File(
      'rust${Platform.pathSeparator}target${Platform.pathSeparator}release${Platform.pathSeparator}$libraryName',
    ),
    File(
      'rust${Platform.pathSeparator}target${Platform.pathSeparator}debug${Platform.pathSeparator}$libraryName',
    ),
  ];
  final library = candidates.where((file) => file.existsSync()).firstOrNull;
  if (library == null) {
    throw StateError('OmniConvert native core not found: $libraryName');
  }
  await RustLib.init(externalLibrary: ExternalLibrary.open(library.path));
}
