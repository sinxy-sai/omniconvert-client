import 'dart:isolate';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'backend_conversion_runner.dart';
import 'tool_error.dart';
import 'tool_io.dart';
import 'tool_registry.g.dart';
import 'tool_runner.dart';

/// Tool ids implemented by this runner in pure Dart, on every platform.
const Set<String> kDartImageToolIds = <String>{
  'png_to_jpeg',
  'jpg_to_png',
  'compress_image',
  'image_to_pdf',
};

/// Whether [toolId] is served by the in-process pure Dart image engine.
bool isDartImageTool(String toolId) => kDartImageToolIds.contains(toolId);

/// The single image/document engine used by **all** platforms.
///
/// One implementation means Web, Windows, Linux, macOS, Android and iOS produce
/// byte-identical output for the same input; the previous split between the Rust
/// core and a Web-only Dart copy silently diverged (JPEG-only compression,
/// cropped PDF pages, a missing `jpg_to_png` branch).
///
/// * CPU heavy work runs in a background isolate through [compute] on native
///   platforms and directly in the calling isolate on Web (where [compute] is a
///   synchronous passthrough anyway).
/// * Text conversion (`docx_to_pdf`, `mobi_to_pdf`) is delegated to the HTTP
///   backend, because those formats need LibreOffice/Calibre.
class DartToolRunner implements CancellableToolRunner {
  DartToolRunner({BackendConversionRunner? backend})
    : _backend = backend ?? const BackendConversionRunner();

  final BackendConversionRunner _backend;
  bool _cancelled = false;

  @override
  void cancel() => _cancelled = true;

  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    _cancelled = false;
    final definition = toolDefinitionFor(request.toolId);
    if (definition == null) {
      throw ToolRunException(unsupportedToolFailure('未知的工具：${request.toolId}'));
    }

    final input = await _resolveInput(request);

    // Server side text conversion keeps going through the HTTP backend.
    if (!definition.isLocal) {
      return _backend.run(
        ToolRequest(
          toolId: request.toolId,
          inputPath: request.inputPath,
          outputPath: request.outputPath,
          options: request.options,
          maxBytes: _byteLimit(request),
          inputBytes: input,
        ),
        onProgress: onProgress,
      );
    }
    if (!isDartImageTool(request.toolId)) {
      throw ToolRunException(
        unsupportedToolFailure('本地引擎尚未实现该工具：${request.toolId}'),
      );
    }

    final limit = _byteLimit(request);
    if (input.length > limit) {
      throw ToolRunException(inputTooLargeFailure(_tooLargeMessage(limit)));
    }

    final stages = <String>{};
    void report(String stage, double value) {
      if (!stages.add(stage)) return;
      onProgress?.call(ToolProgress(stage: stage, progress: value));
    }

    // dart2js 没有 isolate：`ReceivePort.listen` 在 Web 上直接抛
    // `UnsupportedError`。因此在 Web 上不建端口、不传 SendPort，隔离区内的
    // 阶段消息也就无从发送 —— 编码阶段的进度由下面的 `report('encoding')`
    // 在结果返回后补发，用户看到的阶段顺序保持一致。
    ReceivePort? progressPort;
    if (!kIsWeb) {
      progressPort = ReceivePort();
      progressPort.listen((message) {
        if (message == _stageEncoding) report('encoding', 0.5);
      });
    }
    report('decoding', 0);

    final job = _ImageJob(
      toolId: request.toolId,
      bytes: input,
      // Defaults, value ranges and enums all come from the generated registry.
      options: _resolveOptions(definition, request.options),
      explicitOptions: Map<String, String>.unmodifiable(
        <String, String>{
          for (final entry in request.options.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value,
        },
      ),
      progress: progressPort?.sendPort,
    );
    _ImageJobOutcome outcome;
    try {
      outcome = kIsWeb
          ? await _runImageJobEntry(job)
          : await compute(_runImageJobEntry, job);
    } finally {
      progressPort?.close();
    }
    if (_cancelled) throw ToolRunException(cancelledFailure());
    if (outcome.errorCode != null) {
      throw ToolRunException(
        ToolRunFailure(
          code: outcome.errorCode!,
          message: outcome.errorMessage ?? toolErrorMessage(outcome.errorCode!),
        ),
      );
    }

    final output = outcome.bytes;
    if (output == null) {
      throw ToolRunException(invalidInputFailure('处理没有产生任何输出。'));
    }
    // Guarantees the documented decoding -> encoding -> completed sequence even
    // when the isolate stage message raced with the result.
    report('encoding', 0.5);
    final outputPath = await writeToolOutputBytes(request.outputPath, output);
    if (_cancelled) throw ToolRunException(cancelledFailure());
    report('completed', 1);
    return ToolRunResult(
      outputPath: outputPath,
      inputBytes: input.length,
      outputBytes: output.length,
      metadata: <String, String>{
        if (outcome.width != null) 'width': '${outcome.width}',
        if (outcome.height != null) 'height': '${outcome.height}',
      },
      outputBytesData: output,
    );
  }

  Future<Uint8List> _resolveInput(ToolRequest request) async {
    final inMemory = request.inputBytes;
    if (inMemory != null) return inMemory;
    final fromDisk = await readToolInputBytes(request.inputPath);
    if (fromDisk == null) {
      throw ToolRunException(
        invalidInputFailure(
          kIsWeb ? '请先在页面上选择文件，浏览器本地处理需要文件内容。' : '无法读取输入文件，请确认文件仍然存在。',
        ),
      );
    }
    return fromDisk;
  }

  /// The active limit is the tighter of the caller budget and the registry cap.
  static int _byteLimit(ToolRequest request) {
    final requested = request.maxBytes;
    if (requested <= 0) return kMaxInputBytes;
    return requested < kMaxInputBytes ? requested : kMaxInputBytes;
  }

  /// Fills option defaults from the registry, clamps integer ranges and drops
  /// enum values the registry does not declare.
  ///
  /// Nothing about a tool's parameters is hard-coded in the engine: change
  /// `tool/registry.json`, regenerate, and the engine follows.
  static Map<String, String> _resolveOptions(
    ToolDefinition definition,
    Map<String, String> provided,
  ) {
    final resolved = <String, String>{
      for (final option in definition.options)
        if (option.defaultValue != null) option.id: option.defaultValue!,
    };
    for (final option in definition.options) {
      final raw = provided[option.id];
      if (raw == null || raw.isEmpty) continue;
      switch (option.type) {
        case 'integer':
          final value = int.tryParse(raw);
          if (value == null) continue;
          final min = option.min ?? value;
          final max = option.max ?? value;
          resolved[option.id] = '${value < min ? min : (value > max ? max : value)}';
        case 'enum':
          if (option.values.isEmpty || option.values.contains(raw)) {
            resolved[option.id] = raw;
          }
        default:
          resolved[option.id] = raw;
      }
    }
    return Map<String, String>.unmodifiable(resolved);
  }

  static String _tooLargeMessage(int limit) {
    final megabytes = (limit / (1024 * 1024)).toStringAsFixed(0);
    return '文件超出大小限制（最大 $megabytes MB），请换一个更小的文件。';
  }
}

const String _stageEncoding = 'encoding';

/// Immutable, isolate-safe payload for one conversion.
class _ImageJob {
  const _ImageJob({
    required this.toolId,
    required this.bytes,
    required this.options,
    required this.explicitOptions,
    required this.progress,
  });

  final String toolId;
  final Uint8List bytes;

  /// Registry defaults merged with the caller values (integers already clamped
  /// to the registry `min`/`max`, unknown enum values dropped).
  final Map<String, String> options;

  /// The options the caller actually set, so "the control the user touched"
  /// wins over an untouched sibling default.
  final Map<String, String> explicitOptions;

  /// Stage channel back to the UI isolate. Sending `'encoding'` lets the
  /// progress bar reach 50% while the encoder is actually running.
  final SendPort? progress;
}

/// Isolate-safe result envelope: failures are values, not thrown objects, so a
/// corrupt input never surfaces as a raw `RemoteError` in the UI.
class _ImageJobOutcome {
  const _ImageJobOutcome._({
    this.bytes,
    this.width,
    this.height,
    this.errorCode,
    this.errorMessage,
  });

  factory _ImageJobOutcome.success(image.Image source, Uint8List bytes) =>
      _ImageJobOutcome._(
        bytes: bytes,
        width: source.width,
        height: source.height,
      );

  factory _ImageJobOutcome.failure(String code, String message) =>
      _ImageJobOutcome._(errorCode: code, errorMessage: message);

  final Uint8List? bytes;
  final int? width;
  final int? height;
  final String? errorCode;
  final String? errorMessage;
}

/// Isolate entry point. Must stay a top level function for [compute].
Future<_ImageJobOutcome> _runImageJobEntry(_ImageJob job) async {
  try {
    return await _runImageJob(job);
  } catch (_) {
    // A decoder/encoder blowing up on hostile data is an input problem, not a
    // crash: report it as such and keep the isolate boundary clean.
    return _ImageJobOutcome.failure(
      ToolErrorCode.invalidInput,
      '处理图片时出错，文件可能已损坏或不是受支持的图片格式。',
    );
  }
}

Future<_ImageJobOutcome> _runImageJob(_ImageJob job) async {
  final decoded = _decode(job.bytes);
  if (decoded == null) {
    return _ImageJobOutcome.failure(
      ToolErrorCode.invalidInput,
      '无法识别图片内容，文件可能已损坏或不是受支持的图片格式。',
    );
  }
  final source = image.bakeOrientation(decoded);
  final pixels = source.width * source.height;
  if (pixels > kMaxImagePixels && job.toolId != 'compress_image') {
    return _ImageJobOutcome.failure(
      ToolErrorCode.inputTooLarge,
      '图片像素过多（$pixels 像素，上限 $kMaxImagePixels），请先缩小尺寸再处理。',
    );
  }

  switch (job.toolId) {
    case 'png_to_jpeg':
      job.progress?.send(_stageEncoding);
      return _ImageJobOutcome.success(
        source,
        image.encodeJpg(
          _flattenAlpha(source),
          quality: _jpegQuality(job),
        ),
      );
    case 'jpg_to_png':
      job.progress?.send(_stageEncoding);
      return _ImageJobOutcome.success(
        source,
        image.encodePng(source, level: 6),
      );
    case 'compress_image':
      job.progress?.send(_stageEncoding);
      final limited = _fitInsidePixelBudget(source);
      // Format preservation is a hard requirement: a compressed PNG must stay a
      // PNG so transparency and losslessness survive.
      if (_looksLikePng(job.bytes)) {
        return _ImageJobOutcome.success(
          limited,
          image.encodePng(limited, level: _pngLevel(job)),
        );
      }
      return _ImageJobOutcome.success(
        limited,
        image.encodeJpg(limited, quality: _jpegQuality(job)),
      );
    case 'image_to_pdf':
      job.progress?.send(_stageEncoding);
      return _ImageJobOutcome.success(
        source,
        await _encodePdf(source, job.bytes, job.options['layout'] ?? 'fit'),
      );
    default:
      return _ImageJobOutcome.failure(
        ToolErrorCode.unsupportedTool,
        '未知的图片工具：${job.toolId}',
      );
  }
}

image.Image? _decode(Uint8List bytes) {
  // `decodeImage` returns null for unknown containers but *throws* on truncated
  // payloads; both must become the same readable failure.
  try {
    return image.decodeImage(bytes);
  } catch (_) {
    return null;
  }
}

bool _looksLikePng(Uint8List bytes) =>
    bytes.length > 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4e &&
    bytes[3] == 0x47;

bool _looksLikeJpeg(Uint8List bytes) =>
    bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff;

/// Composites [source] over an opaque white canvas, so a PNG with transparency
/// becomes a JPEG without black or grey fringes.
image.Image _flattenAlpha(image.Image source) {
  if (source.numChannels < 4) return source;
  final canvas = image.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  image.fill(canvas, color: image.ColorRgb8(255, 255, 255));
  return image.compositeImage(canvas, source, blend: image.BlendMode.alpha);
}

/// Last-resort memory guard for compression: shrink instead of failing, because
/// the user explicitly asked for a smaller file.
image.Image _fitInsidePixelBudget(image.Image source) {
  final pixels = source.width * source.height;
  if (pixels <= kMaxImagePixels) return source;
  final scale = sqrt(kMaxImagePixels / pixels);
  return image.copyResize(
    source,
    width: (source.width * scale).floor().clamp(1, source.width),
    height: (source.height * scale).floor().clamp(1, source.height),
    interpolation: image.Interpolation.average,
  );
}

/// JPEG quality: whichever control the user actually touched wins, otherwise the
/// registry default.
int _jpegQuality(_ImageJob job) {
  final explicit = job.explicitOptions;
  if (explicit.containsKey('quality')) {
    final value = int.tryParse(job.options['quality'] ?? '');
    if (value != null) return value.clamp(1, 100);
  }
  if (explicit.containsKey('preset')) {
    return _qualityForPreset(explicit['preset']);
  }
  final fallback = int.tryParse(job.options['quality'] ?? '');
  return fallback?.clamp(1, 100) ?? _qualityForPreset(job.options['preset']);
}

int _qualityForPreset(String? preset) => switch (preset) {
  'high' => 92,
  'small' => 60,
  _ => 80,
};

/// PNG has no quality knob; the registry preset maps onto the zlib level
/// (higher level = smaller file, slower encode).
///
/// An explicitly moved quality slider still has an effect, so the control the
/// user touched is never a no-op.
int _pngLevel(_ImageJob job) {
  final explicit = job.explicitOptions;
  if (explicit.containsKey('preset')) {
    return _levelForPreset(explicit['preset']);
  }
  if (explicit.containsKey('quality')) {
    final quality = int.tryParse(job.options['quality'] ?? '');
    if (quality != null) {
      // quality 1 -> level 9 (smallest), quality 100 -> level 1 (fastest).
      return (9 - (quality.clamp(1, 100) - 1) * 8 / 99).round().clamp(1, 9);
    }
  }
  return _levelForPreset(job.options['preset']);
}

int _levelForPreset(String? preset) => switch (preset) {
  'high' => 6,
  'small' => 9,
  _ => 8,
};

/// Builds a single page PDF that never crops the image.
///
/// * `fit` — the page is exactly the image size, so nothing is scaled or cut.
/// * `a4`  — an A4 page with equal margins and the image scaled down/up with
///           [pw.BoxFit.contain], leaving white space instead of cropping.
///
/// A JPEG source is embedded as-is (DCT stream), so converting a photo to PDF
/// costs no extra generation loss and produces a much smaller document than
/// re-encoding it as PNG.
Future<Uint8List> _encodePdf(
  image.Image source,
  Uint8List originalBytes,
  String layout,
) async {
  final pw.MemoryImage memory;
  if (_looksLikeJpeg(originalBytes)) {
    memory = pw.MemoryImage(originalBytes);
  } else {
    // PNG (possibly with alpha) must be flattened onto white, because PDF
    // transparency would otherwise render as a dark or checkerboard page.
    final flat = _flattenAlpha(source);
    memory = pw.MemoryImage(Uint8List.fromList(image.encodePng(flat, level: 6)));
  }
  final pageWidth = source.width.toDouble();
  final pageHeight = source.height.toDouble();
  final document = pw.Document();
  if (layout == 'a4') {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_a4MarginPoints),
        build: (_) => pw.Center(
          child: pw.Image(memory, fit: pw.BoxFit.contain),
        ),
      ),
    );
  } else {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
        build: (_) => pw.Image(memory, fit: pw.BoxFit.contain),
      ),
    );
  }
  return Uint8List.fromList(await document.save());
}

/// 18pt ≈ 6.3mm of breathing room on every side of an A4 page.
const double _a4MarginPoints = 18;