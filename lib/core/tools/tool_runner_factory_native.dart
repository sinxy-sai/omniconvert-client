import 'dart_tool_runner.dart';
import 'tool_runner.dart';

/// Native (desktop/mobile) factory.
///
/// Returns the same pure Dart engine as Web: the Rust core is no longer part of
/// the runtime, so every platform runs byte-identical conversion code.
ToolRunner createToolRunner() => DartToolRunner();