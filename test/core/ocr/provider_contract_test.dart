import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omniconvert/core/ocr/custom_ocr_provider.dart';
import 'package:omniconvert/core/ocr/ocr_provider.dart';

void main() {
  test('custom provider parses capabilities and result', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('capabilities'))
        return http.Response(
          '{"protocolVersion":"ocr-provider-v1","modes":["formula"],"maxBytes":100,"maxTimeoutSeconds":20}',
          200,
        );
      return http.Response(
        '{"requestId":"req-1","latex":"\\\\frac{a}{b}","modelVersion":"mock-1","warnings":[]}',
        200,
      );
    });
    final provider = CustomOcrProvider(
      Uri.parse('https://provider.example.com'),
      client: client,
    );
    expect((await provider.capabilities()).protocolVersion, 'ocr-provider-v1');
    expect(
      (await provider.recognize(
        [1],
        mode: 'formula',
        idempotencyKey: 'key-000000000001',
      )).latex,
      r'\frac{a}{b}',
    );
  });

  test('rejects insecure endpoints unless explicitly local', () async {
    expect(
      () =>
          CustomOcrProvider(Uri.parse('http://example.com')).validateEndpoint(),
      throwsA(isA<OcrProviderException>()),
    );
    expect(
      () => CustomOcrProvider(
        Uri.parse('http://localhost:8000'),
        allowLocalHttp: true,
      ).validateEndpoint(),
      returnsNormally,
    );
  });
}
