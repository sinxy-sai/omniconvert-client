import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/ocr/provider_settings.dart';

void main() {
  test('stores and reloads a validated custom provider endpoint', () async {
    final store = MemoryOcrProviderSettingsStore();
    final settings = OcrProviderSettingsStore(store);
    await settings.saveCustomEndpoint(Uri.parse('https://ocr.example.com'));
    expect(
      await settings.loadCustomEndpoint(),
      Uri.parse('https://ocr.example.com'),
    );
  });

  test('rejects insecure non-local custom provider endpoints', () async {
    final settings = OcrProviderSettingsStore(MemoryOcrProviderSettingsStore());
    expect(
      () => settings.saveCustomEndpoint(Uri.parse('http://ocr.example.com')),
      throwsA(isA<OcrProviderSettingsException>()),
    );
  });
}
