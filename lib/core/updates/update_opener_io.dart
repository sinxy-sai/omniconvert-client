import 'dart:io';

/// Opens a downloaded (and hash-verified) installer with the OS default handler.
///
/// * Windows: `cmd /c start` handles `.exe` and `.msi` alike;
/// * macOS: `open` hands it to Finder / Installer.app;
/// * Linux: AppImage files must be executable before `xdg-open` will run them.
///
/// Returns false when the platform has no handler we know how to drive, so the
/// UI can tell the user where the file is instead of pretending it opened.
Future<bool> openDownloadedInstaller(String path) async {
  if (path.isEmpty) return false;
  final file = File(path);
  if (!file.existsSync()) return false;
  try {
    if (Platform.isWindows) {
      await Process.start('cmd', <String>['/c', 'start', '', path],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', <String>[path],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isLinux) {
      if (path.toLowerCase().endsWith('.appimage')) {
        await Process.run('chmod', <String>['+x', path]);
      }
      await Process.start('xdg-open', <String>[path],
          mode: ProcessStartMode.detached);
      return true;
    }
  } on ProcessException {
    return false;
  }
  return false;
}

/// Opens an https URL in the user's default browser.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  try {
    if (Platform.isWindows) {
      await Process.start('cmd', <String>['/c', 'start', '', url],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', <String>[url],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', <String>[url],
          mode: ProcessStartMode.detached);
      return true;
    }
  } on ProcessException {
    return false;
  }
  return false;
}