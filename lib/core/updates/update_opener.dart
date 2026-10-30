/// 打开「已校验的安装包」与「下载页」的平台入口。
///
/// Web 上没有本地安装包：只能开新窗口到下载页；
/// 桌面端用系统默认方式启动安装包；其他平台返回 false，由 UI 给出可读提示。
library;

export 'update_opener_stub.dart'
    if (dart.library.html) 'update_opener_web.dart'
    if (dart.library.io) 'update_opener_io.dart';