/// Platforms without a shell: nothing can be opened.
library;

Future<bool> openDownloadedInstaller(String path) async => false;

Future<bool> openExternalUrl(String url) async => false;