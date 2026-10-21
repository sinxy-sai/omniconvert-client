import 'package:flutter/material.dart';

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
      await widget.toolService.execute(ToolRequest(
        toolId: _toolId,
        inputPath: input,
        outputPath: output,
        options: options,
      ));
      if (mounted) setState(() => _message = '任务已完成，结果已写入输出路径。');
    } on ToolRunException catch (error) {
      if (mounted) {
        setState(() => _message =
            '${error.failure.code}：${error.failure.message}');
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
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
          ButtonSegment(value: 'png_to_jpeg', label: Text('PNG → JPEG')),
          ButtonSegment(value: 'compress_image', label: Text('图片压缩')),
          ButtonSegment(value: 'image_to_pdf', label: Text('图片 → PDF')),
        ],
        selected: {_toolId},
        onSelectionChanged: _running
            ? null
            : (selection) => setState(() => _toolId = selection.first),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _inputController,
        enabled: !_running,
        decoration: const InputDecoration(
          labelText: '输入文件路径',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _outputController,
        enabled: !_running,
        decoration: const InputDecoration(
          labelText: '输出文件路径',
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
      FilledButton.icon(
        onPressed: _running ? null : _run,
        icon: const Icon(Icons.play_arrow),
        label: Text(_running ? '处理中…' : '开始处理'),
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
      const SizedBox(height: 24),
      const _ToolNote(
        icon: Icons.functions,
        title: '手写公式转 LaTeX',
        description: '官方免费额度或自建识别服务，需登录后使用。',
      ),
      const _ToolNote(
        icon: Icons.description_outlined,
        title: 'DOCX / MOBI → PDF',
        description: '桌面端外部转换器适配器将在后续阶段开放。',
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
