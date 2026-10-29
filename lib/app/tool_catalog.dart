import 'package:flutter/material.dart';

/// 工具在客户端的展示元数据。
///
/// 只描述 UI（名称/图标/处理方式），不包含任何执行逻辑；
/// 执行仍然走 `ToolExecutionService` + `ToolRequest`（本次重设计未改动调用方式）。
enum ToolAccessMode { local, server }

class ToolSpec {
  const ToolSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.mode,
    required this.outputExtension,
    this.inputFormats = 'PNG',
    this.supportsQuality = false,
    this.acceptsImages = true,
    this.comingSoon = false,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ToolAccessMode mode;
  final String outputExtension;
  final String inputFormats;
  final bool supportsQuality;
  final bool acceptsImages;
  final bool comingSoon;

  bool get isLocal => mode == ToolAccessMode.local;

  String get modeLabel => isLocal ? '本机处理' : '服务器转换';
}

/// 工具卡片顺序即产品优先级；第 6 张为「公式识别（暂未开放）」占位卡。
const List<ToolSpec> ocToolCatalog = <ToolSpec>[
  ToolSpec(
    id: 'png_to_jpeg',
    name: '图片 → JPEG',
    description: 'PNG → JPEG，质量可调',
    icon: Icons.swap_horiz_rounded,
    mode: ToolAccessMode.local,
    outputExtension: 'jpg',
    inputFormats: 'PNG',
    supportsQuality: true,
  ),
  ToolSpec(
    id: 'jpg_to_png',
    name: 'JPG → PNG',
    description: '输出 PNG，无损保存',
    icon: Icons.image_outlined,
    mode: ToolAccessMode.local,
    outputExtension: 'png',
    inputFormats: 'JPG · JPEG',
  ),
  ToolSpec(
    id: 'compress_image',
    name: '图片压缩',
    description: '减小体积，画质可控',
    icon: Icons.compress_rounded,
    mode: ToolAccessMode.local,
    outputExtension: 'jpg',
    inputFormats: 'PNG · JPG',
    supportsQuality: true,
  ),
  ToolSpec(
    id: 'image_to_pdf',
    name: '图片 → PDF',
    description: '生成 A4 版式 PDF',
    icon: Icons.picture_as_pdf_outlined,
    mode: ToolAccessMode.local,
    outputExtension: 'pdf',
    inputFormats: 'PNG · JPG',
  ),
  ToolSpec(
    id: 'docx_to_pdf',
    name: 'DOCX → PDF',
    description: '保留排版的文档转换',
    icon: Icons.description_outlined,
    mode: ToolAccessMode.server,
    outputExtension: 'pdf',
    inputFormats: 'DOCX',
    acceptsImages: false,
  ),
  ToolSpec(
    id: 'mobi_to_pdf',
    name: 'MOBI → PDF',
    description: '电子书排版转换',
    icon: Icons.menu_book_outlined,
    mode: ToolAccessMode.server,
    outputExtension: 'pdf',
    inputFormats: 'MOBI',
    acceptsImages: false,
  ),
  ToolSpec(
    id: 'formula_ocr',
    name: '公式识别',
    description: '手写公式转 LaTeX',
    icon: Icons.functions_rounded,
    mode: ToolAccessMode.server,
    outputExtension: 'tex',
    inputFormats: 'PNG · JPG',
    acceptsImages: false,
    comingSoon: true,
  ),
];

ToolSpec? toolSpecFor(String id) {
  for (final spec in ocToolCatalog) {
    if (spec.id == id) return spec;
  }
  return null;
}

const ToolSpec fallbackToolSpec = ToolSpec(
  id: 'unknown',
  name: '文件处理',
  description: '本地文件工具',
  icon: Icons.auto_awesome_motion_outlined,
  mode: ToolAccessMode.local,
  outputExtension: 'bin',
);

/// 任务记录里可能出现的旧工具 ID → 可读名称。
String toolDisplayName(String toolId) {
  final spec = toolSpecFor(toolId);
  if (spec != null) return spec.name;
  return switch (toolId) {
    'image.compress' => '图片压缩',
    'image.to_pdf' => '图片 → PDF',
    'image.png_to_jpeg' => '图片 → JPEG',
    'image.jpg_to_png' => 'JPG → PNG',
    'docx.to_pdf' => 'DOCX → PDF',
    'mobi.to_pdf' => 'MOBI → PDF',
    'formula.ocr' => '公式识别',
    _ => toolId,
  };
}

IconData toolIcon(String toolId) => toolSpecFor(toolId)?.icon ?? fallbackToolSpec.icon;