import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/oc_page.dart';
import '../../../app/widgets/oc_surface.dart';
import '../../../core/ocr/ocr_provider.dart';
import '../../../core/tools/local_file.dart';

typedef ImagePicker = Future<LocalFileSelection?> Function();

class FormulaPage extends StatefulWidget {
  const FormulaPage({
    super.key,
    required this.provider,
    required this.pickImage,
    this.providers = const <String, OcrProvider>{},
    this.unavailable = false,
  });

  final OcrProvider provider;
  final ImagePicker pickImage;
  final Map<String, OcrProvider> providers;

  /// 官方识别服务尚未开放时展示「暂未开放」占位；自建服务配置后为 false。
  final bool unavailable;

  @override
  State<FormulaPage> createState() => _FormulaPageState();
}

class _FormulaPageState extends State<FormulaPage> {
  late final TextEditingController _latexController = TextEditingController();
  LocalFileSelection? _selection;
  OcrResult? _result;
  String? _message;
  OcTone _messageTone = OcTone.info;
  String? _selectedProvider;
  bool _consent = false;
  bool _running = false;

  Map<String, OcrProvider> get _availableProviders => {
    if (widget.providers.isEmpty) '当前服务': widget.provider,
    ...widget.providers,
  };

  OcrProvider get _activeProvider =>
      _availableProviders[_selectedProvider] ?? widget.provider;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _availableProviders.keys.first;
  }

  @override
  void dispose() {
    _latexController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final selection = await widget.pickImage();
    if (!mounted || selection == null) return;
    setState(() {
      _selection = selection;
      _result = null;
      _message = null;
    });
  }

  Future<void> _recognize() async {
    final selection = _selection;
    if (selection == null) {
      setState(() {
        _message = '请先选择一张公式图片。';
        _messageTone = OcTone.warning;
      });
      return;
    }
    if (!_consent) {
      setState(() {
        _message = '请先同意上传图片到识别服务。';
        _messageTone = OcTone.warning;
      });
      return;
    }
    setState(() {
      _running = true;
      _message = null;
      _messageTone = OcTone.info;
    });
    try {
      final result = await _activeProvider.recognize(
        selection.bytes,
        mode: 'formula',
        idempotencyKey: 'formula-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!mounted) return;
      _latexController.text = result.latex;
      setState(() => _result = result);
    } on OcrProviderException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.code == 'recognition_queued'
            ? '识别任务已排队，任务 ID：${error.requestId ?? '未知'}'
            : toolOcrHint(error.code, error.message);
        _messageTone = OcTone.warning;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = '识别没有完成，请稍后重试；图片不会保存在服务器上。';
        _messageTone = OcTone.danger;
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _copyLatex() async {
    await Clipboard.setData(ClipboardData(text: _latexController.text));
    if (!mounted) return;
    setState(() {
      _message = 'LaTeX 已复制到剪贴板。';
      _messageTone = OcTone.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unavailable) return _buildComingSoon(context);
    final selection = _selection;
    final providers = _availableProviders;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return OcPage(
      children: [
        OcPageHeader(
          title: '公式识别',
          description: '上传手写公式图片，识别为可编辑的 LaTeX 代码。',
          trailing: const OcPill(
            label: '使用外部服务',
            tone: OcTone.warning,
            dense: true,
            icon: Icons.cloud_outlined,
          ),
        ),
        const SizedBox(height: OcSpace.md),
        if (providers.length > 1) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedProvider,
            decoration: const InputDecoration(labelText: '识别服务'),
            items: [
              for (final name in providers.keys)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: _running
                ? null
                : (value) => setState(() => _selectedProvider = value),
          ),
          const SizedBox(height: OcSpace.md),
        ],
        OcCard(
          padding: const EdgeInsets.all(OcSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('① 公式图片', style: textTheme.titleMedium),
                  const Spacer(),
                  if (selection != null)
                    TextButton(
                      onPressed: _running ? null : _chooseImage,
                      child: const Text('更换图片'),
                    ),
                ],
              ),
              const SizedBox(height: OcSpace.xs),
              if (selection == null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '支持 PNG / JPG，建议光线均匀、公式水平拍摄。',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: OcSpace.sm),
                    OutlinedButton.icon(
                      onPressed: _running ? null : _chooseImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('选择图片'),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(OcSpace.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: OcRadius.cardBorder,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: Image.memory(
                            Uint8List.fromList(selection.bytes),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: OcSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selection.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '已选择 · 识别时会临时上传',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: OcSpace.xs),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.sm),
        OcCard(
          padding: const EdgeInsets.all(OcSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('② 确认并识别', style: textTheme.titleMedium),
              const SizedBox(height: OcSpace.xs),
              CheckboxListTile(
                value: _consent,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: _running
                    ? null
                    : (value) => setState(() => _consent = value ?? false),
                title: const Text('我同意将这张图片上传到所选识别服务。'),
              ),
              const SizedBox(height: OcSpace.xs),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _running ? null : _recognize,
                      icon: _running
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_running ? '识别中…' : '开始识别'),
                    ),
                  ),
                  if (_running) ...[
                    const SizedBox(width: OcSpace.sm),
                    OutlinedButton(
                      onPressed: null,
                      child: const Text('请稍候'),
                    ),
                  ],
                ],
              ),
              if (_running) ...[
                const SizedBox(height: OcSpace.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: OcSpace.md),
                OcNotice(tone: _messageTone, message: _message!),
              ],
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: OcSpace.md),
          OcCard(
            padding: const EdgeInsets.all(OcSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final inlineActions =
                        MediaQuery.sizeOf(context).width >= 520;
                    return Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: OcSemantics.of(context).success,
                        ),
                        const SizedBox(width: OcSpace.xs),
                        Text('LaTeX 结果', style: textTheme.titleMedium),
                        const SizedBox(width: OcSpace.xs),
                        OcPill(
                          label: _result!.modelVersion,
                          tone: OcTone.neutral,
                          dense: true,
                        ),
                        const Spacer(),
                        if (inlineActions) ...[
                          TextButton.icon(
                            onPressed: _copyLatex,
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('复制 LaTeX'),
                          ),
                          TextButton.icon(
                            onPressed: _running ? null : _recognize,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('重新识别'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: OcSpace.xs),
                if (!(MediaQuery.sizeOf(context).width >= 520))
                  Wrap(
                    spacing: OcSpace.sm,
                    runSpacing: OcSpace.xs,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyLatex,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('复制 LaTeX'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _running ? null : _recognize,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('重新识别'),
                      ),
                    ],
                  ),
                TextField(
                  controller: _latexController,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(
                    fontFamilyFallback: ocMonoFallback,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: '可编辑识别结果',
                  ),
                ),
                const SizedBox(height: OcSpace.sm),
                Text('预览', style: textTheme.labelMedium),
                const SizedBox(height: OcSpace.xs),
                OcCodeBlock(
                  child: SelectableText(
                    _latexController.text,
                    style: const TextStyle(
                      fontFamilyFallback: ocMonoFallback,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
                if (_result!.warnings.isNotEmpty) ...[
                  const SizedBox(height: OcSpace.sm),
                  OcNotice(
                    tone: OcTone.warning,
                    message: '提示：${_result!.warnings.join('、')}',
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: OcSpace.lg),
        const OcNotice(
          tone: OcTone.info,
          title: '关于隐私',
          message: '使用自建识别服务时，图片会发送到该服务；请只配置你信任的地址。',
        ),
        const SizedBox(height: OcSpace.xl),
      ],
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    return OcPage(
      children: [
        OcPageHeader(
          title: '公式识别',
          description: '手写公式照片 → 可编辑的 LaTeX 代码。',
          trailing: const OcPill(
            label: '暂未开放',
            tone: OcTone.warning,
            dense: true,
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(height: OcSpace.lg),
        Container(
          padding: const EdgeInsets.all(OcSpace.xl),
          decoration: BoxDecoration(
            gradient: semantics.brandSoftGradient,
            borderRadius: OcRadius.panelBorder,
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: semantics.cardShadow,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= OcBreakpoints.tablet;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OcIconTile(
                    icon: Icons.functions_rounded,
                    size: 52,
                    gradient: true,
                  ),
                  const SizedBox(height: OcSpace.md),
                  Text('手写公式转 LaTeX', style: textTheme.headlineSmall),
                  const SizedBox(height: OcSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      '识别服务正在筹备中。开放后可以拍照或上传公式图片，'
                      '自动得到可编辑、可复制的 LaTeX 代码。',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: OcSpace.lg),
                  Wrap(
                    spacing: OcSpace.sm,
                    runSpacing: OcSpace.xs,
                    children: const [
                      _ComingSoonStep(index: '1', label: '上传公式图片'),
                      _ComingSoonStep(index: '2', label: '识别为 LaTeX'),
                      _ComingSoonStep(index: '3', label: '编辑并复制'),
                    ],
                  ),
                  const SizedBox(height: OcSpace.lg),
                  Wrap(
                    spacing: OcSpace.sm,
                    runSpacing: OcSpace.xs,
                    children: [
                      FilledButton.icon(
                        onPressed: () => ocNavigate(context, '/settings'),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('配置自建识别服务'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ocNavigate(context, '/tools'),
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text('先用本地工具'),
                      ),
                    ],
                  ),
                ],
              );
              if (!wide) return copy;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: OcSpace.xl),
                  const Expanded(child: _LatexPreview()),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: OcSpace.lg),
        OcCard(
          padding: const EdgeInsets.all(OcSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前可用的能力', style: textTheme.titleMedium),
              const SizedBox(height: OcSpace.sm),
              const _ComingSoonCapability(
                icon: Icons.swap_horiz_rounded,
                title: '格式转换',
                description: '图片 → JPEG / PDF、DOCX / MOBI → PDF',
              ),
              const SizedBox(height: OcSpace.sm),
              const _ComingSoonCapability(
                icon: Icons.compress_rounded,
                title: '图片压缩',
                description: 'PNG / JPG 压缩，画质与体积可控',
              ),
              const SizedBox(height: OcSpace.sm),
              const _ComingSoonCapability(
                icon: Icons.lock_outline_rounded,
                title: '本机处理',
                description: '以上工具都在你的设备上完成，不需要上传',
              ),
            ],
          ),
        ),
        const SizedBox(height: OcSpace.lg),
        const OcNotice(
          tone: OcTone.info,
          title: '为什么还没有开放',
          message: '公式识别需要稳定的云端计算资源。我们会在识别质量与隐私说明都准备好后再开放，'
              '开放前不会要求你上传任何图片。',
        ),
        const SizedBox(height: OcSpace.xl),
      ],
    );
  }
}

class _ComingSoonStep extends StatelessWidget {
  const _ComingSoonStep({required this.index, required this.label});

  final String index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OcSpace.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(OcRadius.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LatexPreview extends StatelessWidget {
  const _LatexPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('上线后的样子', style: textTheme.labelMedium),
        const SizedBox(height: OcSpace.xs),
        const OcCodeBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}'),
              SizedBox(height: 8),
              Text(r'x = \frac{1}{2}\left( \frac{a}{b} \right)'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonCapability extends StatelessWidget {
  const _ComingSoonCapability({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OcIconTile(icon: icon, size: 34, tone: OcTone.neutral),
        const SizedBox(width: OcSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(description, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// OCR 业务错误码 → 可读中文（与工具错误文案分开放，避免误用）。
String toolOcrHint(String code, String message) => switch (code) {
  'not_configured' => '还没有配置识别服务。可以到「设置 → 识别服务」填写自建 HTTPS 地址。',
  'unauthorized' || 'forbidden' => '识别服务拒绝了这次请求，请检查接口地址或访问凭证。',
  'rate_limited' => '识别服务当前繁忙，请稍后重试。',
  'payload_too_large' => '图片太大，请压缩后再试。',
  'unsupported_mode' => '这个识别服务不支持公式模式。',
  'timeout' => '识别超时，请检查网络后重试。',
  _ => message,
};