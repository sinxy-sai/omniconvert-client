/// 非桌面 / 非 IO 平台：没有系统文件管理器可调用。
Future<bool> revealInFileManager(String path) async => false;