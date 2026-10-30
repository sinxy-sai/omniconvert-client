import 'dart_tool_runner.dart';
import 'tool_runner.dart';

/// Web factory.
///
/// Runs the very same [DartToolRunner] used on desktop: `compute` degrades to a
/// direct in-isolate call on Web, so there is a single code path to maintain.
ToolRunner createToolRunner() => DartToolRunner();