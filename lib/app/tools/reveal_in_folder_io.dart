import 'dart:io';

/// 在系统文件管理器中定位输出文件。
///
/// 只在桌面端可用；Web / 移动端返回 false，由调用方降级为提示路径。
Future<bool> revealInFileManager(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', <String>['/select,$path']);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.run('open', <String>['-R', path]);
      return true;
    }
    if (Platform.isLinux) {
      final directory = File(path).parent.path;
      await Process.run('xdg-open', <String>[directory]);
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}