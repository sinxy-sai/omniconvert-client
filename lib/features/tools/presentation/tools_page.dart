import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/error_text.dart';
import '../../../app/format.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/tool_catalog.dart';
import '../../../app/widgets/oc_feedback.dart';
import '../../../app/widgets/oc_page.dart';
import '../../../app/widgets/oc_surface.dart';
import '../../../core/tools/local_file.dart';
import '../../../core/tools/output_file_name.dart';
import '../../../core/tools/tool_execution_service.dart';
import '../../../core/tools/tool_runner.dart';

enum _Outcome { idle, running, success, info, warning, error }

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key, required this.toolService});

  final ToolExecutionService toolService;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();
  final _qualityController = TextEditingController(text: '85');
  String _toolId = 'png_to_jpeg';
  bool _running = false;
  int _quality = 85;
  ToolExecution? _execution;
  Uint8List? _selectedBytes;
  String? _selectedName;
  int? _selectedSize;
  Uint8List? _outputBytes;
  String? _outputName;
  int? _outputSize;
  Map<String, String> _outputMetadata = const {};
  _Outcome _outcome = _Outcome.idle;
  String _message = '';
  String? _errorCode;
  String? _errorRawMessage;
  DateTime? _runStartedAt;
  Duration? _runDuration;

  ToolSpec get _spec => toolSpecFor(_toolId) ?? ocToolCatalog.first;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get _showQuality => _spec.supportsQuality;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  void _resetResult({bool keepFile = true}) {
    if (!keepFile) {
      _selectedBytes = null;
      _selectedName = null;
      _selectedSize = null;
      _inputController.clear();
    }
    _outputBytes = null;
    _outputName = null;
    _outputSize = null;
    _outputMetadata = const {};
    _outcome = _Outcome.idle;
    _message = '';
    _errorCode = null;
    _errorRawMessage = null;
    _runDuration = null;
  }

  void _selectTool(String id) {
    if (_running || id == _toolId) return;
    final spec = toolSpecFor(id);
    if (spec == null) return;
    setState(() {
      _toolId = id;
      _resetResult();
      if (_selectedName != null) {
        _outputController.text = defaultOutputFileName(
          _selectedName!,
          spec.outputExtension,
        );
      }
    });
  }

  Future<void> _run() async {
    final input = _inputController.text.trim();
    final output = _outputController.text.trim();
    if (input.isEmpty || output.isEmpty) {
      setState(() {
        _outcome = _Outcome.warning;
        _message = input.isEmpty
            ? '请先选择文件，或在本机版填写输入文件路径。'
            : '请填写输出文件名，例如 photo.jpg。';
      });
      return;
    }
    setState(() {
      _running = true;
      _outcome = _Outcome.running;
      _message = '';
      _errorCode = null;
      _errorRawMessage = null;
      _outputBytes = null;
      _outputName = null;
      _outputSize = null;
      _outputMetadata = const {};
      _runStartedAt = DateTime.now();
      _runDuration = null;
    });
    // 质量参数只对支持画质调节的工具发送；JPG → PNG 等无损工具不带该参数。
    final options = <String, String>{
      if (_spec.supportsQuality) 'quality': _qualityController.text.trim(),
    };
    if (_toolId == 'image_to_pdf') {
      options.addAll(const {
        'page_size': 'a4',
        'orientation': 'auto',
        'fit': 'contain',
      });
    }
    try {
      final execution = await widget.toolService.start(
        ToolRequest(
          toolId: _toolId,
          inputPath: input,
          outputPath: output,
          options: options,
          inputBytes: _selectedBytes,
        ),
      );
      _execution = execution;
      await execution.completed;
      final result = await execution.result;
      if (!mounted) return;
      if (execution.isCancelled) {
        setState(() {
          _outcome = _Outcome.info;
          _message = '任务已取消，没有写入任何文件。';
        });
        return;
      }
      setState(() {
        _outputBytes = result?.outputBytesData;
        _outputName = output;
        _outputSize = result?.outputBytes;
        _outputMetadata = result?.metadata ?? const {};
        _runDuration = _runStartedAt == null
            ? null
            : DateTime.now().difference(_runStartedAt!);
        if (result?.outputBytesData == null) {
          _outcome = _Outcome.info;
          _message = '任务已完成，结果已写入输出路径。';
        } else {
          _outcome = _Outcome.success;
          _message = '任务已完成，请点击「下载结果」。';
        }
      });
    } on ToolRunException catch (error) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _errorCode = error.failure.code;
        _errorRawMessage = error.failure.message;
        _message = toolErrorHint(error.failure.code);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _errorCode = 'unexpected';
        _errorRawMessage = error.toString();
        _message = genericErrorHint;
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _pickInput() async {
    final selection = await pickLocalFile();
    if (selection == null || !mounted) return;
    setState(() {
      _selectedBytes = Uint8List.fromList(selection.bytes);
      _selectedName = selection.name;
      _selectedSize = selection.bytes.length;
      _inputController.text = selection.path ?? selection.name;
      if (_outputController.text.trim().isEmpty) {
        _outputController.text = defaultOutputFileName(
          selection.name,
          _spec.outputExtension,
        );
      }
      _resetResult();
    });
  }

  void _removeInput() {
    setState(() {
      _selectedBytes = null;
      _selectedName = null;
      _selectedSize = null;
      _inputController.clear();
      _resetResult();
    });
  }

  Future<void> _saveOutput() async {
    final bytes = _outputBytes;
    if (bytes == null) return;
    final saved = await saveLocalFile(bytes, _outputName ?? 'output.bin');
    if (!mounted) return;
    if (saved != null) {
      showOcMessage(context, '结果已保存：$saved', tone: OcTone.success);
    } else {
      showOcMessage(context, '没有拿到保存位置，可以重试或换一个文件名。', tone: OcTone.warning);
    }
  }

  Future<void> _cancel() async {
    final execution = _execution;
    if (execution == null) return;
    await execution.cancel();
    if (!mounted) return;
    setState(() {
      _outcome = _Outcome.info;
      _message = '任务已取消，没有写入任何文件。';
    });
  }

  void _onQualityChanged(int value) {
    setState(() {
      _quality = value;
      _qualityController.text = '$value';
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= OcBreakpoints.desktop;
    final fileColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFileCard(context),
        const SizedBox(height: OcSpace.md),
        _buildRunCard(context),
      ],
    );
    final settingsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSettingsCard(context),
        const SizedBox(height: OcSpace.md),
        _buildTipsCard(context),
      ],
    );
    return OcPage(
      children: [
        OcPageHeader(
          eyebrow: '本地工具箱',
          title: '选择工具',
          description: '图片处理默认在本机完成，不会上传文件；DOCX / MOBI 转换会使用服务器。',
        ),
        const SizedBox(height: OcSpace.lg),
        _buildToolGrid(context),
        const SizedBox(height: OcSpace.md),
        _buildComingSoonBanner(context),
        const SizedBox(height: OcSpace.lg),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: fileColumn),
              const SizedBox(width: OcSpace.md),
              Expanded(flex: 2, child: settingsColumn),
            ],
          )
        else ...[
          fileColumn,
          const SizedBox(height: OcSpace.md),
          settingsColumn,
        ],
        const SizedBox(height: OcSpace.xl),
      ],
    );
  }

  Widget _buildToolGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= OcBreakpoints.tablet
            ? 3
            : 2;
        const spacing = OcSpace.sm;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final tools = ocToolCatalog.where((spec) => !spec.comingSoon).toList();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final spec in tools)
              SizedBox(
                width: itemWidth,
                child: _ToolCard(
                  spec: spec,
                  selected: spec.id == _toolId,
                  onTap: () => _selectTool(spec.id),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 第 7 张卡片单独作为「即将支持」条带，保证工具区仍是整齐的 2×3 网格。
  Widget _buildComingSoonBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OcCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OcSpace.md,
        vertical: OcSpace.sm,
      ),
      onTap: () => ocNavigate(context, '/formula'),
      semanticLabel: '公式识别，暂未开放',
      child: Row(
        children: [
          const OcIconTile(
            icon: Icons.functions_rounded,
            size: 38,
            tone: OcTone.neutral,
          ),
          const SizedBox(width: OcSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('公式识别', style: textTheme.titleSmall),
                Text(
                  '手写公式转 LaTeX · 识别服务筹备中',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: OcSpace.xs),
          const OcPill(label: '暂未开放', tone: OcTone.warning, dense: true),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return OcCard(
      padding: const EdgeInsets.all(OcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('① 选择文件', style: textTheme.titleMedium),
              const Spacer(),
              OcPill(
                label: _spec.modeLabel,
                tone: _spec.isLocal ? OcTone.success : OcTone.warning,
                dense: true,
                icon: _spec.isLocal
                    ? Icons.memory_rounded
                    : Icons.cloud_outlined,
              ),
            ],
          ),
          const SizedBox(height: OcSpace.sm),
          if (_selectedName == null)
            _buildDropZone(context)
          else
            _buildSelectedFile(context),
          if (!kIsWeb) ...[
            const SizedBox(height: OcSpace.md),
            TextField(
              controller: _inputController,
              enabled: !_running,
              decoration: const InputDecoration(
                labelText: '输入文件路径',
                hintText: '选中文件后自动填充，也可以直接粘贴路径',
                prefixIcon: Icon(Icons.folder_open_rounded, size: 18),
              ),
            ),
          ],
          if (_selectedName != null) ...[
            const SizedBox(height: OcSpace.xs),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _spec.isLocal
                        ? '文件只在本机内存中处理，不会上传。'
                        : '转换时会临时上传到服务器，完成后删除。',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropZone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final supported = _spec.inputFormats;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: scheme.outline,
        radius: OcRadius.card,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: OcSpace.md,
          vertical: OcSpace.lg,
        ),
        child: Column(
          children: [
            OcIconTile(
              icon: Icons.cloud_upload_outlined,
              size: 44,
              tone: OcTone.brand,
            ),
            const SizedBox(height: OcSpace.sm),
            Text('点击选择文件', style: textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              '支持 $supported · 单文件不超过 64 MB',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OcSpace.sm),
            OutlinedButton.icon(
              onPressed: _running ? null : _pickInput,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('选择文件'),
            ),
            if (_isDesktop) ...[
              const SizedBox(height: OcSpace.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drag_indicator_rounded, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '桌面端支持拖入文件（即将支持），当前请点击选择。',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = _selectedSize;
    return Container(
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          OcIconTile(icon: _spec.icon, size: 40, tone: OcTone.brand),
          const SizedBox(width: OcSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (size != null) formatFileSize(size),
                    _spec.acceptsImages ? '图片文件' : '文档文件',
                  ].join(' · '),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _running ? null : _removeInput,
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OcCard(
      padding: const EdgeInsets.all(OcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('② 输出设置', style: textTheme.titleMedium),
          const SizedBox(height: OcSpace.sm),
          TextField(
            controller: _outputController,
            enabled: !_running,
            decoration: InputDecoration(
              labelText: '输出文件名',
              hintText: '例如 photo.${_spec.outputExtension}',
              prefixIcon: const Icon(Icons.save_outlined, size: 18),
            ),
          ),
          const SizedBox(height: OcSpace.xs),
          Text(
            '默认与原文件同名，可修改为「${_spec.outputExtension}」结尾的文件名。',
            style: textTheme.bodySmall,
          ),
          if (_showQuality) ...[
            const SizedBox(height: OcSpace.md),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: OcSpace.md),
            Row(
              children: [
                Text('画质', style: textTheme.titleSmall),
                const Spacer(),
                OcPill(
                  label: '$_quality%',
                  tone: OcTone.brand,
                  dense: true,
                ),
              ],
            ),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              label: '$_quality%',
              onChanged: _running
                  ? null
                  : (value) => _onQualityChanged(value.round()),
            ),
            Text(
              '数值越高画质越好、文件越大；日常分享 75–85 已经足够。',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OcCard(
      padding: const EdgeInsets.all(OcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('处理方式', style: textTheme.titleSmall),
          const SizedBox(height: OcSpace.sm),
          const _TipRow(
            icon: Icons.memory_rounded,
            title: '本机处理',
            description: '图片转 JPEG、压缩、转 PDF 在你的设备上完成。',
            tone: OcTone.success,
          ),
          const SizedBox(height: OcSpace.sm),
          const _TipRow(
            icon: Icons.cloud_outlined,
            title: '服务器转换',
            description: 'DOCX / MOBI → PDF 需要上传文件，完成后立即删除。',
            tone: OcTone.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildRunCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return OcCard(
      padding: const EdgeInsets.all(OcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('③ 开始处理', style: textTheme.titleMedium)),
              if (!_running && _outcome != _Outcome.idle)
                TextButton(
                  onPressed: () => setState(() => _resetResult()),
                  child: const Text('重来'),
                ),
            ],
          ),
          const SizedBox(height: OcSpace.xs),
          Text(
            _running ? '处理中，请稍候…' : '确认文件与输出名后开始；处理过程可以取消。',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: OcSpace.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(_running ? '处理中…' : '开始处理'),
                ),
              ),
              if (_running) ...[
                const SizedBox(width: OcSpace.sm),
                OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('取消'),
                ),
              ],
            ],
          ),
          if (_outcome == _Outcome.running) ...[
            const SizedBox(height: OcSpace.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(),
            ),
            const SizedBox(height: OcSpace.xs),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _spec.isLocal ? '正在本机处理文件…' : '正在上传并转换文件…',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (_outcome == _Outcome.success) ...[
            const SizedBox(height: OcSpace.md),
            _buildSuccessCard(context),
          ],
          if (_outcome == _Outcome.error) ...[
            const SizedBox(height: OcSpace.md),
            _buildErrorCard(context),
          ],
          if (_outcome == _Outcome.info || _outcome == _Outcome.warning) ...[
            const SizedBox(height: OcSpace.md),
            OcNotice(
              tone: _outcome == _Outcome.warning ? OcTone.warning : OcTone.info,
              message: _message,
              action: _outcome == _Outcome.info
                  ? TextButton(
                      onPressed: () => setState(() => _resetResult()),
                      child: const Text('再处理一个'),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);
    final details = <String>[
      ?_outputName,
      if (_outputSize != null) formatFileSize(_outputSize!),
      if (_outputMetadata['width'] != null &&
          _outputMetadata['height'] != null)
        '${_outputMetadata['width']}×${_outputMetadata['height']}',
      if (_runDuration != null) '用时 ${formatDuration(_runDuration!)}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: semantics.successContainer,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(
          color: semantics.success.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: semantics.success,
              ),
              const SizedBox(width: OcSpace.xs),
              Text(
                '处理完成',
                style: textTheme.titleSmall?.copyWith(
                  color: semantics.onSuccessContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: OcSpace.xs),
          Text(
            details.join(' · '),
            style: textTheme.bodySmall?.copyWith(
              color: semantics.onSuccessContainer,
            ),
          ),
          if (_outputBytes != null) ...[
            const SizedBox(height: OcSpace.sm),
            Wrap(
              spacing: OcSpace.sm,
              runSpacing: OcSpace.xs,
              children: [
                FilledButton.icon(
                  onPressed: _running ? null : _saveOutput,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('下载结果'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _resetResult()),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('再处理一个'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: semantics.dangerContainer,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: semantics.danger.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 22,
                color: semantics.danger,
              ),
              const SizedBox(width: OcSpace.xs),
              Text(
                '处理没有完成',
                style: textTheme.titleSmall?.copyWith(
                  color: semantics.onDangerContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: OcSpace.xs),
          Text(
            _message,
            style: textTheme.bodyMedium?.copyWith(
              color: semantics.onDangerContainer,
              height: 1.6,
            ),
          ),
          const SizedBox(height: OcSpace.xs),
          Wrap(
            spacing: OcSpace.sm,
            children: [
              FilledButton.icon(
                onPressed: _running ? null : _run,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重试'),
              ),
              TextButton(
                onPressed: _running ? null : _removeInput,
                child: const Text('更换文件'),
              ),
            ],
          ),
          if (_errorCode != null) ...[
            const SizedBox(height: OcSpace.xs),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                dense: true,
                leading: const SizedBox.shrink(),
                title: Text(
                  '技术详情（反馈问题时请附上）',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantics.onDangerContainer,
                  ),
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OcMonoText('错误码：$_errorCode'),
                      if (_errorRawMessage case final raw?) OcMonoText(raw),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final ToolSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '${spec.name}，${spec.comingSoon ? '暂未开放' : spec.modeLabel}',
      child: OcCard(
        onTap: onTap,
        showShadow: selected,
        borderColor: selected ? scheme.primary : null,
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
        padding: const EdgeInsets.all(OcSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OcIconTile(
                  icon: spec.icon,
                  size: 34,
                  gradient: selected,
                  tone: selected ? OcTone.brand : OcTone.neutral,
                ),
                const Spacer(),
                if (spec.comingSoon)
                  const OcPill(
                    label: '暂未开放',
                    tone: OcTone.warning,
                    dense: true,
                  )
                else
                  OcPill(
                    label: spec.isLocal ? '本机' : '服务器',
                    tone: spec.isLocal ? OcTone.success : OcTone.info,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: OcSpace.sm),
            Text(
              spec.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              spec.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final OcTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OcIconTile(icon: icon, size: 32, tone: tone),
        const SizedBox(width: OcSpace.sm),
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
    );
  }
}

/// 虚线描边的拖拽区（Flutter 无内置虚线边框，这里自绘）。
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _strokeWidth = 1.4;
  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}