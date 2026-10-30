import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/theme/app_theme.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tools/local_file.dart';
import 'package:omniconvert/core/tools/tool_execution_service.dart';
import 'package:omniconvert/core/tools/tool_runner.dart';
import 'package:omniconvert/core/tools/tool_registry.g.dart';
import 'package:omniconvert/features/tools/presentation/tools_page.dart';

/// 记录调用的假 runner：默认成功返回 3 字节，可配置为抛错。
class _FakeRunner implements ToolRunner {
  _FakeRunner({this.failure});

  final ToolRunFailure? failure;
  final List<ToolRequest> requests = <ToolRequest>[];
  final List<double> progress = <double>[];

  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    requests.add(request);
    onProgress?.call(const ToolProgress(stage: 'decoding', progress: 0));
    onProgress?.call(const ToolProgress(stage: 'encoding', progress: 0.5));
    final failure = this.failure;
    if (failure != null) throw ToolRunException(failure);
    return ToolRunResult(
      outputPath: request.outputPath,
      inputBytes: request.inputBytes?.length ?? 0,
      outputBytes: 3,
      outputBytesData: Uint8List.fromList(<int>[1, 2, 3]),
      metadata: const {'width': '320', 'height': '240'},
    );
  }
}

Future<LocalFileSelection?> Function() _picks(String name, List<int> bytes) =>
    () async => LocalFileSelection(name: name, bytes: bytes);

String _outputText(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField));
  return field.controller?.text ?? '';
}

/// 点击工具瓦片前先滚到可见区域：宽屏下工具列比视口高，
/// tap 一个在视口外的控件只会命中测试失败（不会自动滚动）。
Future<void> _tapTool(WidgetTester tester, String label) async {
  final finder = find.text(label).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpTools(
  WidgetTester tester, {
  required ToolRunner runner,
  String fileName = 'red.png',
  Future<LocalFileSelection?> Function()? pickFile,
}) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = ToolExecutionService(InMemoryTaskRepository(), runner);
  await tester.pumpWidget(
    MaterialApp(
      theme: OcTheme.light(),
      home: Scaffold(
        body: ToolsPage(
          toolService: service,
          pickFile: pickFile ?? _picks(fileName, <int>[1, 2, 3, 4]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('registry drives every tool the UI offers', () {
    // 6 个工具、两个分类，UI 不允许再出现硬编码清单。
    expect(kToolDefinitions.length, 6);
    expect(
      kToolDefinitions.map((definition) => definition.category).toSet(),
      <String>{'convert', 'compress'},
    );
  });

  testWidgets('tool tiles come from the registry with zh names', (
    tester,
  ) async {
    await _pumpTools(tester, runner: _FakeRunner());

    for (final definition in kToolDefinitions) {
      expect(
        find.text(definition.name['zh']!),
        findsWidgets,
        reason: '工具卡片必须显示 registry 的中文名',
      );
    }
  });

  testWidgets('output file name follows the selected tool', (tester) async {
    await _pumpTools(tester, runner: _FakeRunner());

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(find.text('red.png'), findsOneWidget);
    // PNG → JPEG 的默认输出名。
    expect(_outputText(tester), 'red.jpg');

    // 切到「图片 → PDF」：这就是历史上文件名不跟着变的那个 bug。
    await _tapTool(tester, '图片 → PDF');
    expect(_outputText(tester), 'red.pdf');

    // 再切到 JPEG → PNG，文件格式不匹配时应清空已选文件并给出可读提示。
    await _tapTool(tester, 'JPEG → PNG');
    expect(find.text('red.png'), findsNothing);
    expect(find.textContaining('不是支持的格式'), findsOneWidget);
  });

  testWidgets('output file name follows a newly picked file', (tester) async {
    var name = 'first.png';
    await _pumpTools(
      tester,
      runner: _FakeRunner(),
      pickFile: () async => LocalFileSelection(
        name: name,
        bytes: const <int>[1, 2, 3],
      ),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(_outputText(tester), 'first.jpg');

    name = 'second.png';
    await tester.tap(find.byTooltip('移除文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(_outputText(tester), 'second.jpg');
  });

  testWidgets('parameters are rendered from the registry options', (
    tester,
  ) async {
    await _pumpTools(tester, runner: _FakeRunner());

    // png_to_jpeg 只有整数型 quality。
    expect(find.text('JPEG 质量'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);

    // compress_image 有 enum preset + integer quality。
    await _tapTool(tester, '图片压缩');
    expect(find.text('压缩档位'), findsOneWidget);
    expect(find.text('高画质'), findsOneWidget);
    expect(find.text('均衡'), findsOneWidget);
    expect(find.text('最小体积'), findsOneWidget);

    // image_to_pdf 有 enum layout。
    await _tapTool(tester, '图片 → PDF');
    expect(find.text('版面'), findsOneWidget);
    expect(find.text('整页铺满'), findsOneWidget);
    expect(find.text('A4 留白'), findsOneWidget);
  });

  testWidgets('compression keeps the input format in the output name', (
    tester,
  ) async {
    await _pumpTools(tester, runner: _FakeRunner());

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(_outputText(tester), 'red.jpg');

    // 压缩必须保留原格式：PNG 进来还得是 .png（曾错写成 .jpg）。
    await _tapTool(tester, '图片压缩');
    expect(_outputText(tester), 'red.png');
    expect(find.textContaining('不是支持的格式'), findsNothing);
  });

  testWidgets('compression keeps a jpg input as jpg', (tester) async {
    await _pumpTools(
      tester,
      runner: _FakeRunner(),
      pickFile: _picks('photo.jpeg', <int>[1, 2, 3, 4]),
    );

    await _tapTool(tester, '图片压缩');
    // 先把文件选进来，再确认输出名跟着「工具 + 文件」联动。
    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(_outputText(tester), 'photo.jpg');
    expect(find.text('photo.jpeg'), findsOneWidget);
  });

  testWidgets('switching to an incompatible tool clears the file and explains', (
    tester,
  ) async {
    await _pumpTools(tester, runner: _FakeRunner());

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(find.text('red.png'), findsOneWidget);

    // MOBI → PDF 只收 mobi/azw/azw3/epub：red.png 必须被清掉，
    // 而不是继续显示并悄悄改成 red.pdf。
    await _tapTool(tester, 'MOBI → PDF');
    expect(find.text('red.png'), findsNothing);
    expect(find.textContaining('不是支持的格式'), findsOneWidget);
    expect(_outputText(tester), isEmpty);
  });

  testWidgets('switching tools resets options to the new tool defaults', (
    tester,
  ) async {
    await _pumpTools(tester, runner: _FakeRunner());
    expect(find.text('90%'), findsOneWidget);

    await _tapTool(tester, '图片压缩');
    // 上一页的 90 不能漏到新工具上（compress 的默认是 80）。
    expect(find.text('90%'), findsNothing);
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('running a tool reports progress and offers a download', (
    tester,
  ) async {
    final runner = _FakeRunner();
    await _pumpTools(tester, runner: runner);

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始处理'));
    await tester.pumpAndSettle();

    expect(runner.requests, hasLength(1));
    expect(runner.requests.single.toolId, 'png_to_jpeg');
    expect(runner.requests.single.outputPath, 'red.jpg');
    expect(runner.requests.single.options['quality'], '90');
    expect(find.text('处理完成'), findsOneWidget);
    expect(find.text('下载结果'), findsOneWidget);
  });

  testWidgets('failures show readable Chinese plus a folded error code', (
    tester,
  ) async {
    await _pumpTools(
      tester,
      runner: _FakeRunner(
        failure: const ToolRunFailure(
          code: 'InputTooLarge',
          message: 'input exceeds the 50 MiB limit',
        ),
      ),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始处理'));
    await tester.pumpAndSettle();

    expect(find.textContaining('文件超过大小限制'), findsOneWidget);
    expect(find.text('技术详情（反馈问题时请附上）'), findsOneWidget);
    // 默认折叠：原始英文信息不直接展示给用户。
    expect(find.text('input exceeds the 50 MiB limit'), findsNothing);

    await tester.tap(find.text('技术详情（反馈问题时请附上）'));
    await tester.pumpAndSettle();
    expect(find.text('错误码：InputTooLarge'), findsOneWidget);
    expect(find.text('input exceeds the 50 MiB limit'), findsOneWidget);
  });

  testWidgets('a file with the wrong extension is rejected before running', (
    tester,
  ) async {
    await _pumpTools(
      tester,
      runner: _FakeRunner(),
      pickFile: _picks('notes.docx', <int>[1, 2, 3]),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();

    expect(find.textContaining('不是支持的格式'), findsOneWidget);
    expect(find.text('开始处理'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text ?? '', isEmpty);
  });
}