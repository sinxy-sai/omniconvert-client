import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/error_text.dart';
import '../../../app/format.dart';
import '../../../app/icons/oc_icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/tools/output_name.dart';
import '../../../app/tools/reveal_in_folder.dart';
import '../../../app/tools/selected_tool.dart';
import '../../../app/tools/tool_display.dart';
import '../../../app/widgets/drop_zone.dart';
import '../../../app/widgets/file_drop.dart';
import '../../../app/widgets/file_chip.dart';
import '../../../app/widgets/inline_alert.dart';
import '../../../app/widgets/option_controls.dart';
import '../../../app/widgets/page_layout.dart';
import '../../../app/widgets/result_card.dart';
import '../../../app/widgets/run_progress.dart';
import '../../../app/widgets/surface_card.dart';
import '../../../app/widgets/tone.dart';
import '../../../app/widgets/tool_tile.dart';
import '../../../core/tools/local_file.dart';
import '../../../core/tools/tool_execution_service.dart';
import '../../../core/tools/tool_registry.g.dart';
import '../../../core/tools/tool_runner.dart';

/// 工具页：左侧选工具，右侧「文件 -> 参数 -> 运行」的线性工作区。
///
/// 所有工具信息来自 `kToolDefinitions`；参数区按 registry 的 `options` 动态渲染，
/// 输出文件名统一由 `outputFileNameFor` 决定，切工具 / 换文件都会自动更新。
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key, required this.toolService, this.pickFile});

  final ToolExecutionService toolService;

  /// 选择文件的入口。默认走平台的系统文件选择器；
  /// 测试里可以注入一个返回固定文件的实现。
  final Future<LocalFileSelection?> Function()? pickFile;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

enum _Phase { idle, running, done, failed }

class _ToolsPageState extends State<ToolsPage> {
  String _toolId = kToolDefinitions.first.id;
  final Map<String, String> _options = <String, String>{};
  LocalFileSelection? _file;
  String? _rejection;
  final TextEditingController _outputController = TextEditingController();

  _Phase _phase = _Phase.idle;
  ToolExecution? _execution;
  ToolRunResult? _result;
  double _progress = 0;
  String? _errorCode;
  String? _errorRaw;
  String? _notice;
  Timer? _progressTimer;
  DateTime? _startedAt;
  Duration? _duration;
  String? _savedPath;

  ToolDefinition get _definition =>
      toolDefinitionFor(_toolId) ?? kToolDefinitions.first;

  bool get _running => _phase == _Phase.running;

  bool get _desktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    final pending = ToolSelection.take();
    if (pending != null && toolDefinitionFor(pending) != null) {
      _toolId = pending;
    }
    _applyOptionDefaults();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _outputController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- 状态同步

  void _applyOptionDefaults() {
    _options
      ..clear()
      ..addEntries(
        _definition.options.map(
          (option) => MapEntry<String, String>(
            option.id,
            option.defaultValue ?? '',
          ),
        ),
      );
  }

  /// 工具或文件变化后必须重算输出文件名（历史 bug：切到 PNG->PDF 后仍叫 .jpg）。
  void _syncOutputName() {
    final file = _file;
    if (file == null) {
      _outputController.clear();
      return;
    }
    _outputController.text = defaultOutputName(
      toolId: _toolId,
      inputFileName: file.name,
    );
  }

  void _selectTool(String toolId) {
    if (_running || toolId == _toolId) return;
    setState(() {
      _toolId = toolId;
      _applyOptionDefaults();
      _resetOutcome();
      final file = _file;
      if (file != null && !_definition.accepts(file.name)) {
        _file = null;
        _rejection = rejectionHint(
          reason: 'extension',
          acceptedExtensions: _definition.inputExtensions,
        );
      } else {
        _rejection = null;
      }
      _syncOutputName();
    });
  }

  void _resetOutcome() {
    _phase = _Phase.idle;
    _result = null;
    _errorCode = null;
    _errorRaw = null;
    _notice = null;
    _progress = 0;
    _duration = null;
    _savedPath = null;
  }

  Future<void> _pickFile() async {
    if (_running) return;
    final selection = await (widget.pickFile ?? pickLocalFile)();
    if (selection == null || !mounted) return;
    _acceptFile(
      name: selection.name,
      bytes: selection.bytes,
      path: selection.path,
    );
  }

  void _handleDroppedFile(DroppedFile file) {
    if (_running) return;
    _acceptFile(name: file.name, bytes: file.bytes, path: null);
  }

  void _acceptFile({
    required String name,
    required List<int> bytes,
    String? path,
  }) {
    final definition = _definition;
    setState(() {
      _resetOutcome();
      if (!definition.accepts(name)) {
        _rejection = rejectionHint(
          reason: 'extension',
          acceptedExtensions: definition.inputExtensions,
        );
        _file = null;
        _syncOutputName();
        return;
      }
      if (bytes.isEmpty) {
        _rejection = rejectionHint(
          reason: 'empty',
          acceptedExtensions: definition.inputExtensions,
        );
        _file = null;
        _syncOutputName();
        return;
      }
      if (bytes.length > kMaxInputBytes) {
        _rejection = rejectionHint(
          reason: 'size',
          acceptedExtensions: definition.inputExtensions,
          maxBytes: kMaxInputBytes,
        );
        _file = null;
        _syncOutputName();
        return;
      }
      _rejection = null;
      _file = LocalFileSelection(name: name, bytes: bytes, path: path);
      _syncOutputName();
    });
  }

  void _removeFile() {
    if (_running) return;
    setState(() {
      _file = null;
      _rejection = null;
      _resetOutcome();
      _syncOutputName();
    });
  }

  void _setOption(String optionId, String value) {
    setState(() => _options[optionId] = value);
  }

  // ------------------------------------------------------------------- 运行

  Future<void> _run() async {
    if (_running) return;
    final file = _file;
    if (file == null) {
      setState(() => _notice = '请先选择要处理的文件。');
      return;
    }
    final outputName = _resolvedOutputName();
    if (outputName == null) {
      setState(
        () => _notice = '请填写输出文件名，例如 photo.${_outputExtension()}',
      );
      return;
    }
    setState(() {
      _resetOutcome();
      _phase = _Phase.running;
      _outputController.text = outputName;
      _startedAt = DateTime.now();
    });

    try {
      final execution = await widget.toolService.start(
        ToolRequest(
          toolId: _toolId,
          inputPath: file.path ?? file.name,
          outputPath: outputName,
          options: _options,
          maxBytes: kMaxInputBytes,
          inputBytes: Uint8List.fromList(file.bytes),
        ),
      );
      _execution = execution;
      _watchProgress(execution.taskId);
      await execution.completed;
      final result = await execution.result;
      _progressTimer?.cancel();
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _phase = _Phase.idle;
          _notice = '任务已取消，没有写入任何文件。';
        });
        return;
      }
      setState(() {
        _phase = _Phase.done;
        _progress = 1;
        _result = result;
        _duration = _startedAt == null
            ? null
            : DateTime.now().difference(_startedAt!);
        // 原生端 core 已经落盘并给出真实绝对路径，直接用它，不自己拼。
        _savedPath = _desktop ? result.outputPath : null;
      });
    } on ToolRunException catch (error) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _errorCode = error.failure.code;
        _errorRaw = error.failure.message;
      });
    } catch (error) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _errorCode = 'Unexpected';
        _errorRaw = error.toString();
      });
    }
  }

  void _watchProgress(String taskId) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        try {
          final tasks = await widget.toolService.repository.listRecent(
            limit: 20,
          );
          for (final task in tasks) {
            if (task.taskId != taskId) continue;
            if (task.progress > _progress) {
              setState(() => _progress = task.progress);
            }
            break;
          }
        } catch (_) {
          // 进度只是装饰信息，读失败不应该打断任务。
        }
      },
    );
  }

  Future<void> _cancel() async {
    final execution = _execution;
    if (execution == null) return;
    await execution.cancel();
    _progressTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _notice = '任务已取消，没有写入任何文件。';
    });
  }

  Future<void> _download() async {
    final bytes = _result?.outputBytesData;
    if (bytes == null) return;
    final typed = _outputController.text.trim();
    final name = typed.isEmpty
        ? defaultOutputName(
            toolId: _toolId,
            inputFileName: _file?.name ?? 'output',
          )
        : ensureExtension(typed, _outputExtension());
    final saved = await saveLocalFile(bytes, name);
    if (!mounted) return;
    if (saved == null) {
      showAppToast(
        context,
        '没有拿到保存位置，可以重试或换一个文件名。',
        tone: OcTone.warning,
      );
      return;
    }
    showAppToast(
      context,
      _desktop ? '结果已保存：$saved' : '已开始下载 $name',
      tone: OcTone.success,
    );
  }

  Future<void> _reveal() async {
    final path = _savedPath;
    if (path == null) return;
    final opened = await revealInFileManager(path);
    if (!mounted) return;
    if (!opened) {
      showAppToast(context, '无法自动打开文件夹，文件在：$path', tone: OcTone.warning);
    }
  }

  void _restart() {
    setState(() {
      _resetOutcome();
      _syncOutputName();
    });
  }

  // --------------------------------------------------------------- 输出文件名

  String _outputExtension() =>
      _definition.resolveOutputExtension(extensionOf(_file?.name ?? ''));

  String? _resolvedOutputName() {
    final raw = _outputController.text.trim();
    if (raw.isEmpty) return null;
    return ensureExtension(raw, _outputExtension());
  }

  // ------------------------------------------------------------------ 构建

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= OcBreakpoints.split;
    return PageLayout(
      children: [
        PageHeader(
          eyebrow: '工具',
          title: '选择工具，处理文件',
          description: _definition.isLocal
              ? '图片处理在本机完成，文件不会上传；切换工具时输出文件名会自动更新。'
              : '文档与电子书转换会临时上传到转换服务，处理完成后立即删除。',
          trailing: wide
              ? null
              : StatusPill(
                  label: _definition.isLocal ? '本机处理' : '服务器转换',
                  tone: _definition.isLocal ? OcTone.success : OcTone.info,
                  icon: _definition.isLocal ? OcIcons.chip : OcIcons.cloud,
                  dense: true,
                ),
        ),
        vgap(OcSpace.lg),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 286, child: _buildPicker(context, wide: true)),
              const SizedBox(width: OcSpace.lg),
              Expanded(child: _buildWorkspace(context)),
            ],
          )
        else ...[
          _buildPicker(context, wide: false),
          vgap(OcSpace.lg),
          _buildWorkspace(context),
        ],
        vgap(OcSpace.xl),
      ],
    );
  }

  Widget _buildPicker(BuildContext context, {required bool wide}) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: '选择工具',
            description: '${kToolDefinitions.length} 个工具，按用途分组',
          ),
          vgap(OcSpace.sm),
          for (final group in groupedToolDefinitions()) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: OcSpace.xs,
                bottom: OcSpace.xs,
              ),
              child: Row(
                children: [
                  Text(
                    group.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${group.tools.length}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final definition in group.tools)
              Padding(
                padding: const EdgeInsets.only(bottom: OcSpace.xs),
                child: ToolTile(
                  definition: definition,
                  selected: definition.id == _toolId,
                  onTap: () => _selectTool(definition.id),
                ),
              ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('选择工具', style: textTheme.titleMedium)),
            Text('${kToolDefinitions.length} 个', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: OcSpace.xs),
        // 高度自适应：固定 106dp 在中文 / 大字号下会把瓦片顶出 RenderFlex
        // overflow，这里让一行瓦片按最高的一张取高。
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < kToolDefinitions.length; index++) ...[
                  if (index > 0) const SizedBox(width: OcSpace.xs),
                  SizedBox(
                    width: 188,
                    child: ToolTile(
                      definition: kToolDefinitions[index],
                      selected: kToolDefinitions[index].id == _toolId,
                      dense: true,
                      onTap: () => _selectTool(kToolDefinitions[index].id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspace(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentToolStrip(context),
        vgap(OcSpace.sm),
        _buildFileCard(context),
        vgap(OcSpace.sm),
        _buildOutputCard(context),
        vgap(OcSpace.sm),
        _buildRunCard(context),
      ],
    );
  }

  Widget _buildCurrentToolStrip(BuildContext context) {
    final definition = _definition;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconTile(toolIconFor(definition.id), size: 34, gradient: true),
        const SizedBox(width: OcSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                definition.name['zh'] ?? definition.id,
                style: textTheme.titleMedium?.copyWith(letterSpacing: -0.2),
              ),
              Text(
                definition.summary['zh'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: OcSpace.xxs),
        StatusPill(
          label: definition.isLocal ? '本机处理' : '服务器转换',
          tone: definition.isLocal ? OcTone.success : OcTone.info,
          icon: definition.isLocal ? OcIcons.chip : OcIcons.cloud,
          dense: true,
        ),
        if (MediaQuery.sizeOf(context).width > 520) ...[
          IconButton(
            onPressed: () => _showLimits(context, definition),
            tooltip: '这个工具的格式与限制',
            icon: OcIcon(
              OcIcons.info,
              size: 17,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  void _showLimits(BuildContext context, ToolDefinition definition) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(definition.name['zh'] ?? definition.id),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(definition.summary['zh'] ?? ''),
            const SizedBox(height: OcSpace.sm),
            DetailRow(label: '输入格式', value: formatFlowLabel(definition)),
            DetailRow(
              label: '处理位置',
              value: definition.isLocal ? '本机（不上传）' : '转换服务（用完即删）',
            ),
            DetailRow(label: '单文件上限', value: formatFileSize(kMaxInputBytes)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context) {
    final file = _file;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            index: 1,
            title: '文件',
            description: file == null ? '选择或拖入一个文件' : '确认无误后继续下一步',
            trailing: file == null
                ? null
                : const StatusPill(
                    label: '已选择',
                    tone: OcTone.success,
                    dense: true,
                    icon: OcIcons.check,
                  ),
          ),
          const SizedBox(height: OcSpace.sm),
          if (file == null)
            DropZone(
              onPick: _pickFile,
              onDropFile: _handleDroppedFile,
              acceptedLabel: _definition.inputExtensions
                  .map(formatBadgeLabel)
                  .toSet()
                  .join(' · '),
              maxBytes: kMaxInputBytes,
              enabled: !_running,
              errorText: _rejection,
            )
          else ...[
            FileChip(
              fileName: file.name,
              sizeLabel: formatFileSize(file.bytes.length),
              format: extensionOf(file.name).isEmpty
                  ? null
                  : extensionOf(file.name),
              flowLabel:
                  '${formatBadgeLabel(extensionOf(file.name))} -> ${_outputExtension().toUpperCase()}',
              onRemove: _removeFile,
              busy: _running,
            ),
            if (_rejection != null) ...[
              const SizedBox(height: OcSpace.xs),
              InlineAlert(
                tone: OcTone.warning,
                message: _rejection!,
                dense: true,
              ),
            ],
          ],
          const SizedBox(height: OcSpace.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: OcIcon(
                  _definition.isLocal ? OcIcons.lock : OcIcons.cloud,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _definition.isLocal
                      ? '文件只在这台设备的浏览器内处理，不会上传。'
                      : '转换时会临时上传到转换服务，完成后立即删除。',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard(BuildContext context) {
    final definition = _definition;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(
            index: 2,
            title: '参数与输出',
            description: '参数按工具定义生成，切换工具会自动更新',
          ),
          const SizedBox(height: OcSpace.md),
          ToolOptionsPanel(
            options: definition.options,
            values: _options,
            enabled: !_running,
            onChanged: _setOption,
          ),
          const SizedBox(height: OcSpace.md),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: OcSpace.md),
          Text('输出文件名', style: textTheme.titleSmall),
          const SizedBox(height: OcSpace.xs),
          TextField(
            controller: _outputController,
            enabled: !_running,
            style: const TextStyle(
              fontFamilyFallback: ocMonoFallback,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              hintText: _file == null
                  ? '选择文件后自动生成'
                  : '例如 photo.${_outputExtension()}',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: OcIcon(
                  OcIcons.file,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  widthFactor: 1,
                  child: FormatBadge(_outputExtension()),
                ),
              ),
              helperText: '默认与原文件同名，后缀由工具决定；也可以改成你想要的名字。',
              helperMaxLines: 2,
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _run(),
          ),
        ],
      ),
    );
  }

  Widget _buildRunCard(BuildContext context) {
    final semantics = OcSemantics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            // 标题不要和主按钮同名：两处都叫「开始处理」时，用户与测试都无法
            // 用一句话指向按钮。
            index: 3,
            title: '运行',
            description: _running ? '处理中，可以随时取消' : '确认文件与输出名后开始',
          ),
          const SizedBox(height: OcSpace.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : OcIcon(OcIcons.play, size: 16, color: scheme.onPrimary),
                  label: Text(_running ? '处理中…' : '开始处理'),
                ),
              ),
              if (_running) ...[
                const SizedBox(width: OcSpace.xs),
                OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: OcIcon(OcIcons.stop, size: 15),
                  label: const Text('取消'),
                ),
              ],
            ],
          ),
          if (_running) ...[
            const SizedBox(height: OcSpace.md),
            RunProgress(
              label: _definition.isLocal ? '正在本机处理…' : '正在上传并转换…',
              progress: _progress > 0 ? _progress : null,
            ),
          ],
          if (_notice != null && !_running) ...[
            const SizedBox(height: OcSpace.sm),
            InlineAlert(
              tone: OcTone.warning,
              message: _notice!,
              dense: true,
              action: _notice!.contains('取消')
                  ? TextButton(
                      onPressed: _restart,
                      child: const Text('再处理一个'),
                    )
                  : null,
            ),
          ],
          if (_phase == _Phase.done && _result != null) ...[
            const SizedBox(height: OcSpace.sm),
            ResultCard(
              fileName: _outputController.text.trim().isEmpty
                  ? _result!.outputPath
                  : _outputController.text.trim(),
              sizeLabel: formatFileSize(_result!.outputBytes),
              detailLines: [
                if (_result!.metadata['width'] != null &&
                    _result!.metadata['height'] != null)
                  '${_result!.metadata['width']}x${_result!.metadata['height']}',
                if (_duration != null) '用时 ${formatDuration(_duration!)}',
                if (_savedPath != null) '已保存到 $_savedPath',
              ],
              downloadHint:
                  _desktop && _savedPath != null ? '桌面端已直接写入磁盘' : null,
              onDownload: _result!.outputBytesData == null ? null : _download,
              onReveal: _desktop && _savedPath != null ? _reveal : null,
              onRestart: _restart,
            ),
          ],
          if (_phase == _Phase.failed) ...[
            const SizedBox(height: OcSpace.sm),
            InlineAlert(
              tone: OcTone.danger,
              title: '处理没有完成',
              message: toolErrorHint(_errorCode),
              action: Wrap(
                spacing: OcSpace.xs,
                children: [
                  FilledButton.icon(
                    onPressed: _run,
                    icon: OcIcon(
                      OcIcons.refresh,
                      size: 15,
                      color: scheme.onPrimary,
                    ),
                    label: Text(toolErrorAction(_errorCode)),
                  ),
                  OutlinedButton(
                    onPressed: _removeFile,
                    child: const Text('换一个文件'),
                  ),
                ],
              ),
              details: _errorCode == null
                  ? null
                  : ErrorDetails(
                      code: _errorCode!,
                      rawMessage: _errorRaw,
                      foreground: semantics.onDangerContainer,
                    ),
            ),
          ],
          if (_phase == _Phase.idle && _file != null && _notice == null) ...[
            const SizedBox(height: OcSpace.sm),
            Text(
              _definition.isLocal
                  ? '不会上传文件；处理结果会直接给你下载。'
                  : '上传、转换、下载，服务端不会保留你的文件。',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}