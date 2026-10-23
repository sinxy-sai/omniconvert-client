import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/updates/update_checker.dart';
import '../../../core/updates/update_service.dart';
import '../../../core/ocr/provider_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.providerSettings});
  final OcrProviderSettingsStore? providerSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  UpdateResult? _update;
  bool _checking = false;
  late final OcrProviderSettingsStore _providerSettings =
      widget.providerSettings ?? OcrProviderSettingsStore();
  Uri? _customEndpoint;

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

  Future<void> _configureProvider() async {
    final controller = TextEditingController(
      text: _customEndpoint?.toString() ?? '',
    );
    final endpoint = await showDialog<Uri>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置自建接口'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'HTTPS 服务地址',
            hintText: 'https://ocr.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              try {
                Navigator.pop(context, Uri.parse(controller.text.trim()));
              } catch (_) {}
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (endpoint == null) return;
    try {
      await _providerSettings.saveCustomEndpoint(endpoint);
      if (mounted) setState(() => _customEndpoint = endpoint);
    } on OcrProviderSettingsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
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
      Card.outlined(
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
              subtitle: Text(
                _customEndpoint == null
                    ? '官方服务尚未开放；可配置自建 HTTPS 接口。'
                    : '自建服务：${_customEndpoint!.host}',
              ),
              onTap: _configureProvider,
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('隐私'),
              subtitle: Text('本地处理默认不上传文件。'),
            ),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('配置自建接口'),
              onTap: _configureProvider,
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
