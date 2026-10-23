import 'file_picker_stub.dart'
    if (dart.library.html) 'file_picker_web.dart' as implementation;

class LocalFileSelection {
  const LocalFileSelection({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

Future<LocalFileSelection?> pickLocalImage() => implementation.pickLocalImage();

void downloadLocalFile(List<int> bytes, String fileName) =>
    implementation.downloadLocalFile(bytes, fileName);
