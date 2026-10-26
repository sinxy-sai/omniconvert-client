import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ocr/ocr_provider.dart';
import '../../../core/tools/local_file.dart';

typedef ImagePicker = Future<LocalFileSelection?> Function();

class FormulaPage extends StatefulWidget {
  const FormulaPage({
    super.key,
    required this.provider,
    required this.pickImage,
    this.providers = const <String, OcrProvider>{},
  });

  final OcrProvider provider;
  final ImagePicker pickImage;
  final Map<String, OcrProvider> providers;

  @override
  State<FormulaPage> createState() => _FormulaPageState();
}

class _FormulaPageState extends State<FormulaPage> {
  late final TextEditingController _latexController = TextEditingController();
  LocalFileSelection? _selection;
  OcrResult? _result;
  String? _message;
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
      setState(() => _message = '请先选择公式图片。');
      return;
    }
    if (!_consent) {
      setState(() => _message = '请先同意上传图片到识别服务。');
      return;
    }
    setState(() {
      _running = true;
      _message = null;
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
      if (mounted) {
        setState(() {
          _message = error.code == 'recognition_queued'
              ? '识别任务已排队，任务 ID：${error.requestId ?? '未知'}'
              : '${error.code}：${error.message}';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = '识别失败：$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _copyLatex() async {
    await Clipboard.setData(ClipboardData(text: _latexController.text));
    if (mounted) setState(() => _message = 'LaTeX 已复制。');
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    final providers = _availableProviders;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('公式识别', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('选择公式图片后上传到已选识别服务，结果可继续编辑。'),
        const SizedBox(height: 20),
        if (providers.length > 1)
          DropdownButtonFormField<String>(
            initialValue: _selectedProvider,
            decoration: const InputDecoration(
              labelText: '识别服务',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final name in providers.keys)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: _running
                ? null
                : (value) => setState(() => _selectedProvider = value),
          ),
        if (providers.length > 1) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _running ? null : _chooseImage,
          icon: const Icon(Icons.upload_file),
          label: const Text('选择图片'),
        ),
        if (selection != null) ...[
          const SizedBox(height: 12),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selection.name),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Image.memory(
                      Uint8List.fromList(selection.bytes),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text('图片预览不可用。'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        CheckboxListTile(
          value: _consent,
          contentPadding: EdgeInsets.zero,
          onChanged: _running
              ? null
              : (value) => setState(() => _consent = value ?? false),
          title: const Text('我同意将这张图片上传到所选识别服务。'),
        ),
        FilledButton.icon(
          onPressed: _running ? null : _recognize,
          icon: const Icon(Icons.auto_awesome),
          label: Text(_running ? '识别中…' : '开始识别'),
        ),
        if (_running) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_result != null) ...[
          const SizedBox(height: 20),
          Text('LaTeX 结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _latexController,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '可编辑识别结果',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _copyLatex,
                icon: const Icon(Icons.copy),
                label: const Text('复制 LaTeX'),
              ),
              OutlinedButton.icon(
                onPressed: _running ? null : _recognize,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_latexController.text),
            ),
          ),
          if (_result!.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('提示：${_result!.warnings.join('、')}'),
            ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
