import 'package:flutter/material.dart';

import '../../core/tools/tool_registry.g.dart';
import '../icons/oc_icons.dart';

/// 工具在 UI 层的「装饰映射」：图标、色调、中文名兜底、分类标签。
///
/// 工具清单、摘要、格式、参数**全部**来自 `tool_registry.g.dart`（唯一事实源），
/// 这里只补 UI 需要的图标与历史工具 ID 的中文名，绝不复制工具定义。
OcIconData toolIconFor(String toolId) => switch (toolId) {
  'png_to_jpeg' || 'jpg_to_png' => OcIcons.convert,
  'compress_image' => OcIcons.compress,
  'image_to_pdf' => OcIcons.imageToPdf,
  'docx_to_pdf' => OcIcons.document,
  'mobi_to_pdf' => OcIcons.book,
  // 历史（旧版本任务记录里可能出现的点号 ID）。
  'image.compress' => OcIcons.compress,
  'image.to_pdf' => OcIcons.imageToPdf,
  'image.png_to_jpeg' || 'image.jpg_to_png' => OcIcons.convert,
  'docx.to_pdf' => OcIcons.document,
  'mobi.to_pdf' => OcIcons.book,
  _ => OcIcons.file,
};

/// 工具分类的中文标签（registry 的 category 只有 convert / compress）。
String categoryLabel(String category) => switch (category) {
  'convert' => '格式转换',
  'compress' => '体积压缩',
  _ => '其他',
};

String categoryDescription(String category) => switch (category) {
  'convert' => '在常见格式之间互转，输出文件名自动跟随',
  'compress' => '保持原格式压小体积，画质档位可选',
  _ => '文件处理',
};

/// registry 里的中文名，未知工具（含历史 ID）给可读兜底。
String toolNameFor(String toolId) {
  final definition = toolDefinitionFor(toolId);
  if (definition != null) return definition.name['zh'] ?? definition.id;
  return switch (toolId) {
    'image.compress' => '图片压缩',
    'image.to_pdf' => '图片 → PDF',
    'image.png_to_jpeg' => 'PNG → JPEG',
    'image.jpg_to_png' => 'JPEG → PNG',
    'docx.to_pdf' => 'DOCX → PDF',
    'mobi.to_pdf' => 'MOBI → PDF',
    'formula.ocr' => '公式识别',
    _ => '文件处理',
  };
}

/// 按 registry 的顺序分组（保持产品优先级，不在 UI 里重排）。
List<ToolGroup> groupedToolDefinitions() {
  final groups = <String, List<ToolDefinition>>{};
  for (final definition in kToolDefinitions) {
    groups.putIfAbsent(definition.category, () => <ToolDefinition>[]).add(
      definition,
    );
  }
  return [
    for (final entry in groups.entries)
      ToolGroup(category: entry.key, tools: entry.value),
  ];
}

@immutable
class ToolGroup {
  const ToolGroup({required this.category, required this.tools});

  final String category;
  final List<ToolDefinition> tools;

  String get label => categoryLabel(category);
}

/// 「PNG + JPG → PDF」这样的一行格式说明，供卡片与详情复用。
String formatFlowLabel(ToolDefinition definition, {String arrow = '→'}) {
  final inputs = definition.inputExtensions
      .map((extension) => extension.toUpperCase())
      .toSet()
      .join(' · ');
  final output = definition.keepsFormat
      ? '原格式'
      : definition.outputExtension.toUpperCase();
  return '$inputs $arrow $output';
}

/// 单个格式徽标对应的文本（JPEG 统一显示为 JPG）。
String formatBadgeLabel(String extension) {
  final upper = extension.toUpperCase();
  return upper == 'JPEG' ? 'JPG' : upper;
}