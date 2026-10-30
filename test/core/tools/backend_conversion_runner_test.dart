import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omniconvert/core/tools/backend_conversion_runner.dart';
import 'package:omniconvert/core/tools/tool_runner.dart';

Uint8List _pdfPayload() {
  final header = '%PDF-1.7\n'.codeUnits;
  return Uint8List.fromList([...header, ...List<int>.filled(1100, 0x20)]);
}

ToolRequest _request({
  String toolId = 'mobi_to_pdf',
  int maxBytes = 8 * 1024 * 1024,
}) => ToolRequest(
  toolId: toolId,
  inputPath: 'book.mobi',
  outputPath: 'book.pdf',
  maxBytes: maxBytes,
  inputBytes: Uint8List.fromList(List<int>.filled(64, 7)),
);

Matcher _throwsCode(String code) => throwsA(
  isA<ToolRunException>().having(
    (error) => error.failure.code,
    'code',
    code,
  ),
);

http.Response _error(int status, {String body = '', Map<String, String>? headers}) =>
    http.Response.bytes(
      Uint8List.fromList(body.codeUnits),
      status,
      headers: headers ?? const <String, String>{},
    );

void main() {
  test('maps HTTP 413 to InputTooLarge', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(413)),
    );
    return expectLater(runner.run(_request()), _throwsCode('InputTooLarge'));
  });

  test('maps HTTP 415 to UnsupportedTool', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(415)),
    );
    return expectLater(runner.run(_request()), _throwsCode('UnsupportedTool'));
  });

  test('maps HTTP 5xx to ConverterUnavailable', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(502)),
    );
    return expectLater(
      runner.run(_request()),
      _throwsCode('ConverterUnavailable'),
    );
  });

  test('maps HTTP 429 (server busy) to ConverterUnavailable', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(429)),
    );
    return expectLater(
      runner.run(_request()),
      _throwsCode('ConverterUnavailable'),
    );
  });

  test('prefers the backend x-error-code header over the status', () {
    final runner = BackendConversionRunner(
      client: MockClient(
        (_) async => _error(400, headers: {'x-error-code': 'input_too_large'}),
      ),
    );
    return expectLater(runner.run(_request()), _throwsCode('InputTooLarge'));
  });

  test('maps transport failures to NetworkError', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => throw const SocketFailure()),
    );
    return expectLater(runner.run(_request()), _throwsCode('NetworkError'));
  });

  test('rejects oversized uploads before hitting the network', () async {
    var called = false;
    final runner = BackendConversionRunner(
      client: MockClient((_) async {
        called = true;
        return _error(200);
      }),
    );
    await expectLater(
      runner.run(_request(maxBytes: 8)),
      _throwsCode('InputTooLarge'),
    );
    expect(called, isFalse);
  });

  test('a non PDF success body is ConverterUnavailable', () {
    final runner = BackendConversionRunner(
      client: MockClient(
        (_) async => http.Response.bytes(
          Uint8List.fromList('<html>nope</html>'.codeUnits),
          200,
        ),
      ),
    );
    return expectLater(
      runner.run(_request()),
      _throwsCode('ConverterUnavailable'),
    );
  });

  test('returns the converted PDF and reports completion', () async {
    final payload = _pdfPayload();
    final progress = <ToolProgress>[];
    final runner = BackendConversionRunner(
      client: MockClient((_) async => http.Response.bytes(payload, 200)),
    );

    final result = await runner.run(_request(), onProgress: progress.add);

    expect(result.outputBytesData, isNotNull);
    expect(result.outputBytes, payload.length);
    expect(String.fromCharCodes(result.outputBytesData!.sublist(0, 5)), '%PDF-');
    expect(progress.first.stage, 'uploading');
    expect(progress.last.progress, 1);
  });

  test('local tools never reach the backend', () {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(500)),
    );
    return expectLater(
      runner.run(_request(toolId: 'png_to_jpeg')),
      _throwsCode('UnsupportedTool'),
    );
  });

  test('every produced failure message is readable Chinese', () async {
    final runner = BackendConversionRunner(
      client: MockClient((_) async => _error(503)),
    );
    try {
      await runner.run(_request());
      fail('expected a failure');
    } on ToolRunException catch (error) {
      expect(error.failure.message, contains('服务'));
      expect(error.failure.message, isNot(contains('Exception')));
    }
  });
}

class SocketFailure implements Exception {
  const SocketFailure();
}