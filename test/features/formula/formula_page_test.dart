import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/ocr/ocr_provider.dart';
import 'package:omniconvert/core/tools/local_file.dart';
import 'package:omniconvert/features/formula/presentation/formula_page.dart';

class _FakeProvider implements OcrProvider {
  int calls = 0;

  @override
  Future<OcrCapabilities> capabilities() async => const OcrCapabilities(
    protocolVersion: 'ocr-provider-v1',
    modes: ['formula'],
    maxBytes: 1024,
    maxTimeoutSeconds: 20,
  );

  @override
  Future<OcrResult> recognize(
    List<int> image, {
    required String mode,
    required String idempotencyKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls++;
    return const OcrResult(
      requestId: 'req-1',
      latex: r'\frac{a}{b}',
      modelVersion: 'test-1',
      warnings: [],
    );
  }
}

class _QueuedProvider extends _FakeProvider {
  @override
  Future<OcrResult> recognize(
    List<int> image, {
    required String mode,
    required String idempotencyKey,
    Duration timeout = const Duration(seconds: 20),
  }) => Future.error(const OcrProviderException(
    'recognition_queued',
    'Recognition is queued',
    retryable: true,
    requestId: 'req-queued',
  ));
}

void main() {
  testWidgets('requires consent before recognizing a selected image', (
    tester,
  ) async {
    final provider = _FakeProvider();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaPage(
            provider: provider,
            pickImage: () async =>
                const LocalFileSelection(name: 'formula.png', bytes: [1, 2, 3]),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择图片'));
    await tester.pump();
    expect(find.text('formula.png'), findsOneWidget);
    await tester.tap(find.text('开始识别'));
    await tester.pump();
    expect(provider.calls, 0);
    expect(find.text('请先同意上传图片到识别服务。'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('开始识别'));
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    expect(find.text(r'\frac{a}{b}'), findsNWidgets(2));
  });

  testWidgets('copies editable latex to the clipboard', (tester) async {
    final provider = _FakeProvider();
    final clipboard = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaPage(
            provider: provider,
            pickImage: () async =>
                const LocalFileSelection(name: 'formula.png', bytes: [1]),
          ),
        ),
      ),
    );
    await tester.tap(find.text('选择图片'));
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('开始识别'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制 LaTeX'));
    expect(clipboard, [r'\frac{a}{b}']);
  });

  testWidgets('shows queued recognition task id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaPage(
            provider: _QueuedProvider(),
            pickImage: () async => const LocalFileSelection(
              name: 'formula.png',
              bytes: [1],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('选择图片'));
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('开始识别'));
    await tester.pumpAndSettle();
    expect(find.text('识别任务已排队，任务 ID：req-queued'), findsOneWidget);
  });
}
