import 'file_picker_stub.dart'
    if (dart.library.html) 'file_picker_web.dart'
    if (dart.library.io) 'file_picker_io.dart'
    as implementation;

class LocalFileSelection {
  const LocalFileSelection({
    required this.name,
    required this.bytes,
    this.path,
  });

  final String name;
  final List<int> bytes;
  final String? path;
}

Future<LocalFileSelection?> pickLocalImage() => implementation.pickLocalImage();

Future<String?> saveLocalFile(List<int> bytes, String fileName) =>
    implementation.saveLocalFile(bytes, fileName);
