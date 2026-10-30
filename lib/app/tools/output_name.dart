import '../../core/tools/output_file_name.dart' as core;

export '../../core/tools/output_file_name.dart'
    show outputFileNameFor, baseFileName;

/// UI 侧对「输出文件名」的唯一出口。
///
/// 规则全部来自 core 的 [core.outputFileNameFor]（它读 registry），
/// 页面只负责在工具变化 / 文件变化时调用它，不再自己拼后缀。
String defaultOutputName({
  required String toolId,
  required String inputFileName,
}) => core.outputFileNameFor(toolId: toolId, inputFileName: inputFileName);

/// 取小写扩展名（不含点）；没有扩展名时返回空串。
String extensionOf(String fileName) {
  final name = core.baseFileName(fileName);
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// 用户手改文件名后仍然保证后缀正确：缺后缀就补上，后缀不对就替换。
String ensureExtension(String fileName, String extension) {
  final name = core.baseFileName(fileName.trim());
  if (name.isEmpty) return '';
  final target = extension.toLowerCase();
  final current = extensionOf(name);
  if (current == target || (target == 'jpg' && current == 'jpeg')) return name;
  if (current.isEmpty) return '$name.$target';
  final dot = name.lastIndexOf('.');
  return '${name.substring(0, dot)}.$target';
}