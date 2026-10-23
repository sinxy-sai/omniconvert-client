import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/updates/update_checker.dart';
import '../../../core/updates/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  UpdateResult? _update;
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final info = await _packageInfo;
      final result = await const UpdateService().check(info.version);
      if (mounted) {
        setState(() => _update = result);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _update = UpdateResult(UpdateState.invalidManifest, error: error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('设置', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      Card.outlined(
        child: ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: const Text('版本更新'),
          subtitle: FutureBuilder(
            future: _packageInfo,
            builder: (context, snapshot) => Text(_statusText(snapshot.data)),
          ),
          trailing: _checking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.refresh),
                ),
        ),
      ),
      const SizedBox(height: 12),
      const Card.outlined(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('本地工具无需登录'),
              subtitle: Text('官方公式识别开放后才需要账号。'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('识别服务'),
              subtitle: Text('后续可选择官方服务或配置自建接口。'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('隐私'),
              subtitle: Text('本地处理默认不上传文件。'),
            ),
          ],
        ),
      ),
    ],
  );

  String _statusText(PackageInfo? info) {
    final version = info?.version ?? '0.1.0';
    final result = _update;
    if (result == null) return '当前版本 $version · 点击刷新检查官网发布信息。';
    return switch (result.state) {
      UpdateState.current => '当前版本 $version · 已是最新版本。',
      UpdateState.available =>
        '发现新版本 ${result.release?.version} · ${result.release?.releaseNotes}',
      UpdateState.required => '当前版本过旧，必须升级到 ${result.release?.version}。',
      UpdateState.invalidManifest => '版本检查失败，请稍后重试。',
    };
  }
}
