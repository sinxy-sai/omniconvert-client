import 'package:http/http.dart' as http;

import 'http_ocr_provider.dart';
import 'ocr_provider.dart';

class CustomOcrProvider extends HttpOcrProvider {
  const CustomOcrProvider(
    super.baseUri, {
    super.client,
    this.allowLocalHttp = false,
  });
  final bool allowLocalHttp;
  @override
  void validateEndpoint({bool allowLocalHttp = false}) =>
      super.validateEndpoint(allowLocalHttp: this.allowLocalHttp);
  @override
  Future<OcrResult> recognize(
    List<int> image, {
    required String mode,
    required String idempotencyKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    validateEndpoint(allowLocalHttp: allowLocalHttp);
    final request =
        http.MultipartRequest('POST', baseUri.resolve('/v1/recognize'))
          ..headers['Idempotency-Key'] = idempotencyKey
          ..fields['mode'] = mode
          ..fields['timeoutSeconds'] = '${timeout.inSeconds}'
          ..files.add(
            http.MultipartFile.fromBytes(
              'image',
              image,
              filename: 'formula.png',
            ),
          );
    final response = await client
        .send(request)
        .timeout(timeout)
        .then(http.Response.fromStream);
    return parseResult(response);
  }
}
