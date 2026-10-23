import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/ocr/provider_settings.dart';
import 'package:omniconvert/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('configures and displays a custom provider host', (tester) async {
    final store = OcrProviderSettingsStore(MemoryOcrProviderSettingsStore());
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(providerSettings: store)),
    );
    await tester.tap(find.text('识别服务'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('配置自建接口').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://ocr.example.com');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('自建服务：ocr.example.com'), findsOneWidget);
  });
}
