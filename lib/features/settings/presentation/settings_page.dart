import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/error_text.dart';
import '../../../app/icons/oc_icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/inline_alert.dart';
import '../../../app/widgets/page_layout.dart';
import '../../../app/widgets/surface_card.dart';
import '../../../app/widgets/tone.dart';
import '../../../core/tools/backend_conversion_runner.dart';
import '../../../core/updates/android_installer.dart';
import '../../../core/updates/update_checker.dart';
import '../../../core/updates/update_downloader.dart';
import '../../../core/updates/update_opener.dart';
import '../../../core/updates/update_service.dart';

/// 设置页：外观、版本与更新、服务地址、隐私、关于。
///
/// 本轮不做 OCR，因此没有「识别服务」配置；所有设置只作用于这台设备。
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _version;
  bool _loadingVersion = true;
  bool _checking = false;
  UpdateResult? _update;
  bool _downloading = false;
  double? _downloadFraction;
  String? _downloadedPath;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadVersion();
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

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      // 重新检查时清掉上一次的下载结果，避免旧安装包信息误导用户。
      _downloadedPath = null;
      _downloadError = null;
      _downloadFraction = null;
    });
    try {
      final version = _version;
      if (version == null) {
        if (!mounted) return;
        setState(
          () => _update = const UpdateResult(UpdateState.invalidManifest),
        );
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

  /// 一键更新：下载 → 校验 SHA-256 → 交给系统安装。
  ///
  /// Web 没有本地安装包，改为打开官网下载页；Android 走原生安装器，
  /// 桌面端用系统默认方式打开已校验的安装包。
  Future<void> _downloadUpdate() async {
    final release = _update?.release;
    if (release == null || _downloading) return;
    setState(() {
      _downloading = true;
      _downloadFraction = null;
      _downloadedPath = null;
      _downloadError = null;
    });
    try {
      final path = await const UpdateDownloader().download(
        release,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadFraction = progress.fraction);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadedPath = path;
        _downloading = false;
      });
      if (kIsWeb) return;
      if (defaultTargetPlatform == TargetPlatform.android) {
        await const AndroidInstaller().installVerifiedApk(path, release.sha256);
        return;
      }
      final opened = await openDownloadedInstaller(path);
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _downloadError = '安装包已下载并校验，但没能自动打开。文件位置：$path';
        });
      }
    } on UpdateDownloadCancelled {
      if (mounted) setState(() => _downloading = false);
    } on UpdateManifestException catch (error) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadError = error.message;
        });
      }
    } on UpdateSha256Mismatch catch (error) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadError = '更新包下载没有完成，请检查网络后重试。';
        });
      }
    }
  }

  Future<void> _openDownloadPage() async {
    final url = _update?.release?.downloadUrl.toString();
    if (url == null) return;
    final opened = await openExternalUrl(url);
    if (!mounted) return;
    if (!opened) showAppToast(context, '无法打开浏览器，请手动访问 $url');
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showAppToast(context, '已复制$label', tone: OcTone.success);
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      maxWidth: 900,
      children: [
        const PageHeader(
          eyebrow: '设置',
          title: '设置',
          description: '外观、版本与更新、服务地址都只影响这台设备。',
        ),
        vgap(OcSpace.lg),
        SectionHeader(
          title: '外观',
          description: '默认跟随系统，也可以固定在浅色或深色',
        ),
        vgap(OcSpace.xs),
        _AppearanceCard(
          mode: widget.themeMode,
          onChanged: widget.onThemeModeChanged,
        ),
        vgap(OcSpace.xl),
        SectionHeader(
          title: '版本与更新',
          description: '从官网发布信息检查新版本，安装前校验 SHA-256',
        ),
        vgap(OcSpace.xs),
        _buildUpdateCard(context),
        vgap(OcSpace.xl),
        SectionHeader(
          title: '服务地址',
          description: '转换服务与更新清单的来源，开源版可自行替换',
        ),
        vgap(OcSpace.xs),
        SurfaceCard(
          padding: const EdgeInsets.all(OcSpace.md),
          child: Column(
            children: [
              _AddressRow(
                label: '转换服务',
                value: BackendConversionRunner.defaultBaseUrl,
                onCopy: () =>
                    _copy('转换服务地址', BackendConversionRunner.defaultBaseUrl),
              ),
              const SizedBox(height: OcSpace.xs),
              _AddressRow(
                label: '更新清单',
                value: releaseManifestUrl,
                onCopy: () => _copy('更新清单地址', releaseManifestUrl),
              ),
            ],
          ),
        ),
        vgap(OcSpace.xl),
        const SectionHeader(
          title: '数据与隐私',
          description: '文件默认留在你的设备上',
        ),
        vgap(OcSpace.xs),
        const SurfaceCard(
          padding: EdgeInsets.symmetric(
            horizontal: OcSpace.md,
            vertical: OcSpace.sm,
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: OcIcons.chip,
                title: '本地工具无需登录',
                description: '图片转换、压缩、导出 PDF 都在本机完成，访客模式即可使用。',
                tone: OcTone.success,
              ),
              _InfoRow(
                icon: OcIcons.cloud,
                title: '服务器转换会明确标注',
                description: 'DOCX / MOBI 转换会临时上传，完成后立即删除，不会留存副本。',
                tone: OcTone.info,
              ),
              _InfoRow(
                icon: OcIcons.shield,
                title: '不收集使用数据',
                description: '没有埋点与广告 SDK，不需要手机号或邮箱。',
                tone: OcTone.neutral,
              ),
            ],
          ),
        ),
        vgap(OcSpace.xl),
        const SectionHeader(title: '关于'),
        vgap(OcSpace.xs),
        SurfaceCard(
          padding: const EdgeInsets.all(OcSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OmniConvert',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '本地优先的文件工具箱 · 客户端',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: _loadingVersion
                        ? '读取中'
                        : _version == null
                        ? '版本未知'
                        : 'v$_version',
                    tone: OcTone.neutral,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: OcSpace.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: 'OmniConvert',
                      applicationVersion: _version,
                      applicationLegalese: 'Apache License 2.0',
                    ),
                    icon: const OcIcon(OcIcons.document, size: 16),
                    label: const Text('开源许可'),
                  ),
                ],
              ),
            ],
          ),
        ),
        vgap(OcSpace.xl),
      ],
    );
  }

  Widget _buildUpdateCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);
    final result = _update;
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loadingVersion
                          ? '正在读取版本…'
                          : _version == null
                          ? '版本信息暂不可用'
                          : '当前版本 v$_version',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '更新包在安装前会校验 SHA-256，校验失败不会安装。',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OcSpace.xs),
              OutlinedButton.icon(
                onPressed: _checking ? null : _checkForUpdates,
                icon: _checking
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const OcIcon(OcIcons.refresh, size: 15),
                label: Text(_checking ? '检查中…' : '检查更新'),
              ),
            ],
          ),
          const SizedBox(height: OcSpace.sm),
          _buildUpdateStatus(context, result, textTheme, semantics),
        ],
      ),
    );
  }

  Widget _buildUpdateStatus(
    BuildContext context,
    UpdateResult? result,
    TextTheme textTheme,
    OcSemantics semantics,
  ) {
    if (result == null) {
      return Text(
        '还没有检查过。点「检查更新」可以看是否有新版本。',
        style: textTheme.bodySmall,
      );
    }
    return switch (result.state) {
      UpdateState.current => const InlineAlert(
        tone: OcTone.success,
        title: '已是最新版本',
        message: '当前版本已经是最新，不需要更新。',
        dense: true,
      ),
      UpdateState.available || UpdateState.required => Builder(
        builder: (context) {
          final release = result.release;
          return InlineAlert(
            tone: result.state == UpdateState.required
                ? OcTone.warning
                : OcTone.info,
            title: result.state == UpdateState.required
                ? '版本过旧，建议立即更新'
                : '发现新版本 v${release?.version ?? ''}',
            message: result.state == UpdateState.required
                ? '最新版本 v${release?.version ?? ''}；旧版本可能存在兼容问题。'
                : '可以到官网下载页获取安装包，安装前会校验文件完整性。',
            details: release == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: OcSpace.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (release.releaseNotes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              release.releaseNotes,
                              style: textTheme.bodySmall?.copyWith(
                                color: semantics.onInfoContainer,
                              ),
                            ),
                          ),
                        DetailRow(
                          label: '目标平台',
                          value: '${release.platform} · ${release.arch}',
                        ),
                        DetailRow(
                          label: 'SHA-256',
                          value: release.sha256,
                          mono: true,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: OcSpace.xs,
                            runSpacing: OcSpace.xxs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (kIsWeb)
                                FilledButton.icon(
                                  onPressed: _openDownloadPage,
                                  icon: const OcIcon(OcIcons.external, size: 15),
                                  label: const Text('打开发布页'),
                                )
                              else
                                FilledButton.icon(
                                  onPressed: _downloading ? null : _downloadUpdate,
                                  icon: _downloading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const OcIcon(OcIcons.download, size: 15),
                                  label: Text(_downloading ? '下载中…' : '下载并安装'),
                                ),
                              TextButton.icon(
                                onPressed: () =>
                                    _copy('下载地址', release.downloadUrl.toString()),
                                icon: const OcIcon(OcIcons.copy, size: 15),
                                label: const Text('复制下载地址'),
                              ),
                            ],
                          ),
                        ),
                        if (_downloading) ...[
                          const SizedBox(height: OcSpace.xs),
                          LinearProgressIndicator(
                            value: _downloadFraction,
                            minHeight: 4,
                          ),
                          if (_downloadFraction != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '已下载 ${(_downloadFraction! * 100).toStringAsFixed(0)}%',
                                style: textTheme.bodySmall?.copyWith(
                                  color: semantics.onInfoContainer,
                                ),
                              ),
                            ),
                        ],
                        if (_downloadedPath != null && !_downloading)
                          Padding(
                            padding: const EdgeInsets.only(top: OcSpace.xs),
                            child: Text(
                              '安装包已下载并通过 SHA-256 校验。',
                              style: textTheme.bodySmall?.copyWith(
                                color: semantics.onInfoContainer,
                              ),
                            ),
                          ),
                        if (_downloadError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: OcSpace.xs),
                            child: Text(
                              _downloadError!,
                              style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            dense: true,
          );
        },
      ),
      UpdateState.invalidManifest => const InlineAlert(
        tone: OcTone.warning,
        title: '这次检查没有成功',
        message: updateCheckErrorHint,
        dense: true,
      ),
    };
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(ThemeMode, String, OcIconData)>[
      (ThemeMode.system, '跟随系统', OcIcons.monitor),
      (ThemeMode.light, '浅色', OcIcons.sun),
      (ThemeMode.dark, '深色', OcIcons.moon),
    ];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Row(
        children: [
          for (final (value, label, icon) in options) ...[
            Expanded(
              child: Semantics(
                button: true,
                selected: value == mode,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onChanged == null ? null : () => onChanged!(value),
                  borderRadius: BorderRadius.circular(OcRadius.iconTile),
                  child: AnimatedContainer(
                    duration: OcDuration.fast,
                    curve: OcDuration.curve,
                    padding: const EdgeInsets.symmetric(
                      vertical: OcSpace.sm,
                      horizontal: OcSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: value == mode
                          ? scheme.primaryContainer
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(OcRadius.iconTile),
                      border: Border.all(
                        color: value == mode
                            ? scheme.primary.withValues(alpha: 0.4)
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        OcIcon(
                          icon,
                          size: 19,
                          color: value == mode
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: textTheme.labelMedium?.copyWith(
                            color: value == mode
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (value != options.last.$1) const SizedBox(width: OcSpace.xs),
          ],
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: textTheme.bodySmall),
        ),
        Expanded(
          child: MonoText(
            value,
            fontSize: 12.5,
            maxLines: 2,
            selectable: true,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: onCopy,
          tooltip: '复制$label地址',
          icon: OcIcon(
            OcIcons.copy,
            size: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
    this.tone = OcTone.neutral,
  });

  final OcIconData icon;
  final String title;
  final String description;
  final OcTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OcSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 30, tone: tone),
          const SizedBox(width: OcSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 1),
                Text(description, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}