import 'dart:typed_data';

/// Reads the whole input file, or `null` when it cannot be read.
Future<Uint8List?> readToolInputBytes(String path) async => null;

/// Writes produced bytes and returns the path that was actually written.
///
/// On web the caller keeps the bytes in memory, so the requested path is
/// returned untouched.
Future<String> writeToolOutputBytes(String path, Uint8List bytes) async => path;