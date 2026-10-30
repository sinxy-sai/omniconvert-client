import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tool_error.dart';
import 'tool_registry.g.dart';
import 'tool_runner.dart';

/// Calls the OmniConvert conversion service for the formats that need real
/// office/ebook tooling (`docx_to_pdf`, `mobi_to_pdf`, …).
///
/// Everything this runner throws is one of the canonical [ToolErrorCode]s with
/// readable Chinese copy: the status code, the backend `x-error-code` header and
/// transport failures are all folded into that single taxonomy so the UI never
/// has to understand HTTP.
class BackendConversionRunner {
  const BackendConversionRunner({
    this.client,
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 240),
  });

  static const String defaultBaseUrl = String.fromEnvironment(
    'OMNICONVERT_API_BASE_URL',
    defaultValue: 'https://www.sinxysai.site/api/v1',
  );

  final http.Client? client;
  final String baseUrl;
  final Duration timeout;

  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    final definition = toolDefinitionFor(request.toolId);
    if (definition == null || definition.isLocal) {
      throw ToolRunException(
        unsupportedToolFailure('该工具不需要服务端转换：${request.toolId}'),
      );
    }
    final input = request.inputBytes;
    if (input == null || input.isEmpty) {
      throw ToolRunException(invalidInputFailure('文档转换需要先选择文件。'));
    }
    final limit = _byteLimit(request);
    if (input.length > limit) {
      throw ToolRunException(inputTooLargeFailure(_tooLargeMessage(limit)));
    }

    final httpClient = client ?? http.Client();
    final boundary =
        '----OmniConvertBoundary${DateTime.now().microsecondsSinceEpoch}';
    onProgress?.call(const ToolProgress(stage: 'uploading', progress: 0));
    try {
      final http.Response response;
      try {
        response = await httpClient
            .post(
              Uri.parse('$baseUrl/conversions/pdf'),
              body: _multipartBody(input, request.inputPath, boundary),
              headers: {
                'Content-Type': 'multipart/form-data; boundary=$boundary',
                'Accept': 'application/pdf',
              },
            )
            .timeout(timeout);
      } on TimeoutException {
        throw ToolRunException(
          ToolRunFailure(
            code: ToolErrorCode.converterUnavailable,
            message: '转换超时，服务器处理时间过长，请稍后重试。',
          ),
        );
      } on ToolRunException {
        rethrow;
      } catch (_) {
        throw ToolRunException(
          ToolRunFailure(
            code: ToolErrorCode.networkError,
            message: toolErrorMessage(ToolErrorCode.networkError),
          ),
        );
      }

      if (response.statusCode != 200) {
        throw ToolRunException(
          conversionFailureFor(
            statusCode: response.statusCode,
            serverCode: response.headers['x-error-code'],
            detail: _serverDetail(response),
          ),
        );
      }
      final output = Uint8List.fromList(response.bodyBytes);
      if (!_looksLikePdf(output)) {
        throw ToolRunException(
          ToolRunFailure(
            code: ToolErrorCode.converterUnavailable,
            message: '转换服务返回的文件不是有效的 PDF，请稍后重试。',
          ),
        );
      }
      onProgress?.call(const ToolProgress(stage: 'completed', progress: 1));
      return ToolRunResult(
        outputPath: request.outputPath,
        inputBytes: input.length,
        outputBytes: output.length,
        outputBytesData: output,
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static int _byteLimit(ToolRequest request) {
    final requested = request.maxBytes;
    if (requested <= 0) return kMaxInputBytes;
    return requested < kMaxInputBytes ? requested : kMaxInputBytes;
  }

  static String _tooLargeMessage(int limit) =>
      '文件超出大小限制（最大 ${(limit / (1024 * 1024)).toStringAsFixed(0)} MB），'
      '请换一个更小的文件。';

  static bool _looksLikePdf(Uint8List bytes) =>
      bytes.length > 1024 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46 &&
      bytes[4] == 0x2d;

  /// Extracts a short human readable detail from an error response body.
  static String? _serverDetail(http.Response response) {
    if (response.body.isEmpty) return null;
    final body = response.body.trim();
    if (body.length > 200) return null;
    if (body.contains(RegExp(r'^[{[]|Traceback|Exception'))) return null;
    return body;
  }

  List<int> _multipartBody(Uint8List bytes, String path, String boundary) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final head =
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$name"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n';
    return <int>[
      ...head.codeUnits,
      ...bytes,
      ...'\r\n--$boundary--\r\n'.codeUnits,
    ];
  }
}