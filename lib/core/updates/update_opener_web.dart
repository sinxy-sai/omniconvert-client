// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// The browser has no local installer: the only meaningful action is the
/// download page, which we open in a new tab.
Future<bool> openDownloadedInstaller(String path) async => false;

Future<bool> openExternalUrl(String url) async {
  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.scheme != 'https') return false;
  final window = html.window.open(url, '_blank');
  // A popup blocker leaves a window object with a null-ish closed state and no
  // navigation; there is no reliable signal, so treat "we asked" as success and
  // let the caller keep the copyable link as a fallback.
  return window.closed != true;
}