// GENERATED FROM OmniConvert-client/tool/registry.json — DO NOT EDIT BY HAND.
// Regenerate with: python tool/generate_registry.py

/// One tunable option of a tool.
class ToolOptionDefinition {
  const ToolOptionDefinition({
    required this.id,
    required this.type,
    required this.label,
    this.min,
    this.max,
    this.defaultValue,
    this.values = const <String>[],
  });

  final String id;
  final String type;
  final Map<String, String> label;
  final int? min;
  final int? max;
  final String? defaultValue;
  final List<String> values;
}

/// A tool as declared by the single-source registry.
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.summary,
    required this.category,
    required this.engine,
    required this.inputExtensions,
    required this.outputExtension,
    this.options = const <ToolOptionDefinition>[],
  });

  final String id;
  final Map<String, String> name;
  final Map<String, String> summary;
  final String category;
  final String engine;
  final List<String> inputExtensions;

  /// `same` means the output keeps the input format (compression).
  final String outputExtension;
  final List<ToolOptionDefinition> options;

  bool get isLocal => engine == 'local';

  bool get keepsFormat => outputExtension == 'same';

  /// Output extension for a concrete input file.
  String resolveOutputExtension(String inputExtension) {
    final normalised = inputExtension.toLowerCase().replaceFirst('.', '');
    if (!keepsFormat) return outputExtension;
    return normalised == 'jpeg' ? 'jpg' : normalised;
  }

  bool accepts(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return inputExtensions.contains(name.substring(dot + 1).toLowerCase());
  }

  String? optionDefault(String optionId) {
    for (final option in options) {
      if (option.id == optionId) return option.defaultValue;
    }
    return null;
  }
}

const int kMaxInputBytes = 52428800;
const int kMaxImagePixels = 100000000;

const List<ToolDefinition> kToolDefinitions = <ToolDefinition>[
  ToolDefinition(
    id: 'png_to_jpeg',
    name: <String, String>{'zh': 'PNG → JPEG', 'en': 'PNG to JPEG'},
    summary: <String, String>{'zh': '透明底自动合成白色背景，质量可调', 'en': 'Flattens transparency to white, quality adjustable'},
    category: 'convert',
    engine: 'local',
    inputExtensions: <String>['png'],
    outputExtension: 'jpg',
    options: <ToolOptionDefinition>[
      ToolOptionDefinition(id: 'quality', type: 'integer', label: <String, String>{'zh': 'JPEG 质量', 'en': 'JPEG quality'}, min: 1, max: 100, defaultValue: '90'),
    ],
  ),
  ToolDefinition(
    id: 'jpg_to_png',
    name: <String, String>{'zh': 'JPEG → PNG', 'en': 'JPEG to PNG'},
    summary: <String, String>{'zh': '转为无损 PNG，便于二次编辑', 'en': 'Lossless PNG output for further editing'},
    category: 'convert',
    engine: 'local',
    inputExtensions: <String>['jpg', 'jpeg'],
    outputExtension: 'png',
  ),
  ToolDefinition(
    id: 'compress_image',
    name: <String, String>{'zh': '图片压缩', 'en': 'Compress image'},
    summary: <String, String>{'zh': '保持原格式压缩，体积更小、画质可控', 'en': 'Keeps the input format, smaller size, tunable quality'},
    category: 'compress',
    engine: 'local',
    inputExtensions: <String>['png', 'jpg', 'jpeg'],
    outputExtension: 'same',
    options: <ToolOptionDefinition>[
      ToolOptionDefinition(id: 'preset', type: 'enum', label: <String, String>{'zh': '压缩档位', 'en': 'Compression preset'}, defaultValue: 'balanced', values: <String>['high', 'balanced', 'small']),
      ToolOptionDefinition(id: 'quality', type: 'integer', label: <String, String>{'zh': '画质', 'en': 'Quality'}, min: 1, max: 100, defaultValue: '80'),
    ],
  ),
  ToolDefinition(
    id: 'image_to_pdf',
    name: <String, String>{'zh': '图片 → PDF', 'en': 'Image to PDF'},
    summary: <String, String>{'zh': '整页铺满或按 A4 留白，不裁切', 'en': 'Full-bleed or A4 with margins, never cropped'},
    category: 'convert',
    engine: 'local',
    inputExtensions: <String>['png', 'jpg', 'jpeg'],
    outputExtension: 'pdf',
    options: <ToolOptionDefinition>[
      ToolOptionDefinition(id: 'layout', type: 'enum', label: <String, String>{'zh': '版面', 'en': 'Layout'}, defaultValue: 'fit', values: <String>['fit', 'a4']),
    ],
  ),
  ToolDefinition(
    id: 'mobi_to_pdf',
    name: <String, String>{'zh': 'MOBI → PDF', 'en': 'MOBI to PDF'},
    summary: <String, String>{'zh': '电子书排版转换，上传后即用即删', 'en': 'Ebook layout conversion, uploads are deleted after use'},
    category: 'convert',
    engine: 'server',
    inputExtensions: <String>['mobi', 'azw', 'azw3', 'epub'],
    outputExtension: 'pdf',
  ),
  ToolDefinition(
    id: 'docx_to_pdf',
    name: <String, String>{'zh': 'DOCX → PDF', 'en': 'DOCX to PDF'},
    summary: <String, String>{'zh': '保留排版的文档转换', 'en': 'Layout-preserving document conversion'},
    category: 'convert',
    engine: 'server',
    inputExtensions: <String>['docx'],
    outputExtension: 'pdf',
  ),
];

/// Look up a tool definition, or `null` for an unknown id.
ToolDefinition? toolDefinitionFor(String id) {
  for (final definition in kToolDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}
