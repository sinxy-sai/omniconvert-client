import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/tools/local_file.dart';
import '../../../core/tools/output_file_name.dart';
import '../../../core/tools/tool_execution_service.dart';
import '../../../core/tools/tool_runner.dart';

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
  String? _message;
  ToolExecution? _execution;
  Uint8List? _selectedBytes;
  String? _selectedName;
  Uint8List? _outputBytes;
  String? _outputName;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final input = _inputController.text.trim();
    final output = _outputController.text.trim();
    if (input.isEmpty || output.isEmpty) {
      setState(() => _message = '请输入输入文件和输出文件路径。');
      return;
    }
    setState(() {
      _running = true;
      _message = null;
      _outputBytes = null;
      _outputName = null;
    });
    final options = <String, String>{'quality': _qualityController.text.trim()};
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
      _outputBytes = result?.outputBytesData;
      _outputName = output;
      if (mounted && !execution.isCancelled) {
        setState(
          () => _message = result?.outputBytesData == null
              ? '任务已完成，结果已写入输出路径。'
              : '任务已完成，请点击“下载结果”。',
        );
      }
    } on ToolRunException catch (error) {
      if (mounted) {
        setState(
          () => _message = '${error.failure.code}：${error.failure.message}',
        );
      }
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
      _inputController.text = selection.path ?? selection.name;
      if (_outputController.text.trim().isEmpty) {
        _outputController.text = defaultOutputFileName(
          selection.name,
          _toolId == 'image_to_pdf' || _toolId.endsWith('_to_pdf') ? 'pdf' : 'jpg',
        );
      }
    });
  }

  Future<void> _saveOutput() async {
    final bytes = _outputBytes;
    if (bytes == null) return;
    final saved = await saveLocalFile(bytes, _outputName ?? 'output.bin');
    if (mounted && saved != null) setState(() => _message = '结果已保存：$saved');
  }

  Future<void> _cancel() async {
    final execution = _execution;
    if (execution == null) return;
    await execution.cancel();
    if (mounted) setState(() => _message = '任务已取消。');
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('选择工具', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('图片处理默认在本机完成，不会上传文件。桌面端支持直接输入本地路径。'),
      const SizedBox(height: 24),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'png_to_jpeg', label: Text('图片 → JPEG')),
          ButtonSegment(value: 'compress_image', label: Text('图片压缩')),
          ButtonSegment(value: 'image_to_pdf', label: Text('图片 → PDF')),
          const ButtonSegment(value: 'docx_to_pdf', label: Text('DOCX → PDF')),
          const ButtonSegment(value: 'mobi_to_pdf', label: Text('MOBI → PDF')),
        ],
        selected: {_toolId},
        onSelectionChanged: _running
            ? null
            : (selection) => setState(() => _toolId = selection.first),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_running && !kIsWeb,
              decoration: InputDecoration(
                labelText: _selectedName == null ? '输入文件路径' : '已选择文件',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _running ? null : _pickInput,
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _outputController,
        enabled: !_running,
        decoration: const InputDecoration(
          labelText: '输出文件名',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _qualityController,
        enabled: !_running && _toolId != 'image_to_pdf',
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'JPEG 质量（1-100）',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _running ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: Text(_running ? '处理中…' : '开始处理'),
            ),
          ),
          if (_running) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.stop),
              label: const Text('取消'),
            ),
          ],
        ],
      ),
      if (_running) ...[
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
      ],
      if (_message != null) ...[
        const SizedBox(height: 16),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_message!),
          ),
        ),
      ],
      if (_outputBytes != null) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _running ? null : _saveOutput,
          icon: const Icon(Icons.download),
          label: const Text('下载结果'),
        ),
      ],
      const SizedBox(height: 24),
      const _ToolNote(
        icon: Icons.functions,
        title: '手写公式转 LaTeX',
        description: '官方免费额度或自建识别服务，需登录后使用。',
      ),
      const _ToolNote(
        icon: Icons.description_outlined,
        title: 'DOCX / MOBI → PDF',
        description: '通过服务器转换，桌面端和 Web 端都可使用。',
      ),
    ],
  );
}

class _ToolNote extends StatelessWidget {
  const _ToolNote({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
    ),
  );
}
