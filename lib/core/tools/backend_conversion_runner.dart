import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tool_runner.dart';

class BackendConversionRunner {
  const BackendConversionRunner({http.Client? client}) : _client = client;

  static const baseUrl = String.fromEnvironment(
    'OMNICONVERT_API_BASE_URL',
    defaultValue: 'https://www.sinxysai.site/api/v1',
  );

  final http.Client? _client;

  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    final input = request.inputBytes;
    if (input == null) {
      throw const ToolRunException(ToolRunFailure(
        code: 'InputBytesRequired', message: '文档转换需要文件内容。',
      ));
    }
    final client = _client ?? http.Client();
    final boundary = '----OmniConvertBoundary${DateTime.now().microsecondsSinceEpoch}';
    onProgress?.call(const ToolProgress(stage: 'uploading', progress: 0));
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/conversions/pdf'),
        body: _multipartBody(input, request.inputPath, boundary),
        headers: {'Content-Type': 'multipart/form-data; boundary=$boundary'},
      );
      if (response.statusCode != 200) {
        throw ToolRunException(ToolRunFailure(
          code: response.headers['x-error-code'] ?? 'ConversionFailed',
          message: response.body.isEmpty ? '服务器转换失败。' : response.body,
        ));
      }
      final output = Uint8List.fromList(response.bodyBytes);
      onProgress?.call(const ToolProgress(stage: 'completed', progress: 1));
      return ToolRunResult(outputPath: request.outputPath, inputBytes: input.length, outputBytes: output.length, outputBytesData: output);
    } on ToolRunException {
      rethrow;
    } catch (error) {
      throw ToolRunException(ToolRunFailure(code: 'ConversionUnavailable', message: '无法连接文档转换服务：$error'));
    } finally {
      if (_client == null) client.close();
    }
  }

  List<int> _multipartBody(Uint8List bytes, String path, String boundary) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final head = '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$name"\r\nContent-Type: application/octet-stream\r\n\r\n';
    return <int>[...head.codeUnits, ...bytes, ...'\r\n--$boundary--\r\n'.codeUnits];
  }
}
