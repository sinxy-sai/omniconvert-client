/// Web/stub storage: there is no local update artifact to delete.
Future<String> saveUpdate(String fileName, Stream<List<int>> bytes) async {
  throw UnsupportedError('APK updates are only available on Android');
}

Future<void> deleteUpdate(String path) async {}