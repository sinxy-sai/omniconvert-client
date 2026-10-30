/// Platform-neutral input/output byte access for the pure Dart tool runner.
///
/// Web builds never touch the filesystem channel: the caller always passes
/// `ToolRequest.inputBytes` and receives `ToolRunResult.outputBytesData`, so the
/// stub implementation is a no-op. Desktop/mobile builds read and write real
/// files.
library;

export 'tool_io_stub.dart' if (dart.library.io) 'tool_io_io.dart';