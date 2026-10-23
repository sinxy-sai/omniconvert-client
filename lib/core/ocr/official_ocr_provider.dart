import 'package:http/http.dart' as http;

import 'custom_ocr_provider.dart';

class OfficialOcrProvider extends CustomOcrProvider {
  const OfficialOcrProvider(Uri endpoint, {http.Client? client})
    : super(endpoint, client: client);
}
