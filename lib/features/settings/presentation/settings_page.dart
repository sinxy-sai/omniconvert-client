import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/error_text.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/oc_brand.dart';
import '../../../app/widgets/oc_feedback.dart';
import '../../../app/widgets/oc_page.dart';
import '../../../app/widgets/oc_surface.dart';
import '../../../core/ocr/provider_settings.dart';
import '../../../core/updates/update_checker.dart';
import '../../../core/updates/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.providerSettings});

  final OcrProviderSettingsStore? providerSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final OcrProviderSettingsStore _providerSettings =
      widget.providerSettings ?? OcrProviderSettingsStore();
  String? _version;
  bool _loadingVersion = true;
  UpdateResult? _update;
  bool _checking = false;
  Uri? _customEndpoint;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadCustomEndpoint();
  }

  Future<void> _loadVersion() async {
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
    } catch (_) {
      version = null;
    }
    if (!mounted) return;
    setState(() {
      _version = version;
      _loadingVersion = false;
    });
  }

  Future<void> _loadCustomEndpoint() async {
    final endpoint = await _providerSettings.loadCustomEndpoint();
    if (mounted) setState(() => _customEndpoint = endpoint);
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final version = _version;
      if (version == null) {
        setState(() => _update = null);
        showOcMessage(context, '暂时读不到版本信息，请稍后重试。', tone: OcTone.warning);
        return;
      }
      final result = await const UpdateService().check(version);
      if (mounted) setState(() => _update = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _update = const UpdateResult(UpdateState.invalidManifest),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '仅支持使用 HTTPS 的识别服务地址，不要带路径。保存后重新进入公式页生效。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: OcSpace.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'HTTPS 服务地址',
                hintText: 'https://ocr.example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.trim();
              final parsed = Uri.tryParse(raw);
              if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
                showOcMessage(context, '请填写完整的 HTTPS 地址，例如 https://ocr.example.com。', tone: OcTone.warning);
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (endpoint == null) return;
    try {
      await _providerSettings.saveCustomEndpoint(endpoint);
      if (!mounted) return;
      setState(() => _customEndpoint = endpoint);
      showOcMessage(context, '已保存识别服务地址。', tone: OcTone.success);
    } on OcrProviderSettingsException catch (error) {
      if (!mounted) return;
      showOcMessage(context, error.message, tone: OcTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OcPage(
      children: [
        OcPageHeader(
          title: '设置',
          description: '版本更新、识别服务与隐私说明。所有设置都保存在本机。',
        ),
        const SizedBox(height: OcSpace.lg),
        const OcSectionHeader(
          title: '版本与更新',
          subtitle: '从官网发布信息检查新版本。',
        ),
        OcCard(
          padding: const EdgeInsets.all(OcSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OcIconTile(
                    icon: Icons.system_update_outlined,
                    size: 40,
                    tone: OcTone.brand,
                  ),
                  const SizedBox(width: OcSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('版本更新', style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          _loadingVersion
                              ? '正在读取版本…'
                              : _version == null
                              ? '版本信息暂不可用'
                              : '当前版本 v$_version',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: OcSpace.sm),
                  OutlinedButton.icon(
                    onPressed: _checking ? null : _checkForUpdates,
                    icon: _checking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_checking ? '检查中…' : '检查更新'),
                  ),
                ],
              ),
              const SizedBox(height: OcSpace.md),
              _buildUpdateStatus(context),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.xl),
        const OcSectionHeader(
          title: '识别与授权',
          subtitle: '本地工具不需要账号；公式识别服务尚未开放。',
        ),
        OcCard(
          padding: const EdgeInsets.symmetric(vertical: OcSpace.xs),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('本地工具无需登录'),
                subtitle: const Text('访客模式即可使用全部本地工具，公式识别开放后才需要账号。'),
                trailing: const OcPill(
                  label: '访客模式',
                  tone: OcTone.success,
                  dense: true,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('识别服务'),
                subtitle: Text(
                  _customEndpoint == null
                      ? '官方服务尚未开放；可配置自建 HTTPS 接口。'
                      : '自建服务：${_customEndpoint!.host}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _configureProvider,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('配置自建接口'),
                subtitle: const Text('仅支持 HTTPS 地址，用于自建公式识别服务。'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _configureProvider,
              ),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.xl),
        const OcSectionHeader(
          title: '隐私与外观',
          subtitle: '文件默认留在你的设备上。',
        ),
        OcCard(
          padding: const EdgeInsets.symmetric(vertical: OcSpace.xs),
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('本机处理'),
                subtitle: Text('图片转 JPEG、压缩、转 PDF 在本机完成，不上传文件。'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cloud_queue_rounded),
                title: Text('服务器转换会明确标注'),
                subtitle: Text('DOCX / MOBI → PDF 会临时上传，转换完成后立即删除。'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.visibility_off_outlined),
                title: Text('不收集使用数据'),
                subtitle: Text('没有埋点与广告 SDK，不需要手机号或邮箱。'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.dark_mode_outlined),
                title: Text('外观'),
                subtitle: Text('跟随系统设置，自动切换浅色 / 深色主题。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.xl),
        const OcSectionHeader(title: '关于'),
        OcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OcBrandLockup(markSize: 30),
                  const Spacer(),
                  OcPill(
                    label: _version == null ? 'v—' : 'v$_version',
                    tone: OcTone.neutral,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: OcSpace.sm),
              Text(
                'OmniConvert 是一个本地优先的文件工具箱：格式转换、图片压缩，打开就能用。',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: OcSpace.sm),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.code_rounded),
                title: const Text('开源许可'),
                subtitle: const Text('客户端以 Apache-2.0 许可证开源；查看第三方依赖许可。'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'OmniConvert',
                  applicationVersion: _version,
                  applicationLegalese: 'Apache License 2.0',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('问题反馈'),
                subtitle: const Text('欢迎在项目仓库提交 issue，附上任务页的技术详情会更快定位。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.xl),
      ],
    );
  }

  Widget _buildUpdateStatus(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_checking) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OcSpace.xs),
          Text('正在检查更新…', style: textTheme.bodySmall),
        ],
      );
    }
    final result = _update;
    if (result == null) {
      return Text(
        '点击「检查更新」查看最新版本；发现新版本后会提示下载地址。',
        style: textTheme.bodySmall,
      );
    }
    return switch (result.state) {
      UpdateState.current => const OcNotice(
        tone: OcTone.success,
        title: '已是最新版本',
        message: '当前版本已是最新，无需更新。',
      ),
      UpdateState.available => OcNotice(
        tone: OcTone.info,
        title: '发现新版本 v${result.release?.version ?? ''}',
        message: [
          if (result.release?.releaseNotes.isNotEmpty ?? false)
            result.release!.releaseNotes,
          '请到官网下载页获取安装包，安装前会校验 SHA-256。',
        ].join('\n'),
      ),
      UpdateState.required => OcNotice(
        tone: OcTone.warning,
        title: '当前版本过旧，建议立即更新',
        message:
            '最新版本 v${result.release?.version ?? ''}。旧版本可能存在兼容问题，请尽快更新。',
      ),
      UpdateState.invalidManifest => const OcNotice(
        tone: OcTone.warning,
        title: '这次检查没有成功',
        message: updateCheckErrorHint,
      ),
    };
  }
}