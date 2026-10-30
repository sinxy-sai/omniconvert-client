import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/theme/app_theme.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tasks/task_status.dart';
import 'package:omniconvert/core/tools/tool_registry.g.dart';
import 'package:omniconvert/features/home/presentation/home_page.dart';

Future<void> _pumpHome(
  WidgetTester tester,
  TaskRepository repository, {
  Size size = const Size(1440, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: OcTheme.light(),
      home: Scaffold(body: HomePage(taskRepository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home states the value proposition and a primary CTA', (
    tester,
  ) async {
    await _pumpHome(tester, InMemoryTaskRepository());

    expect(find.text('文件处理，简单一点。'), findsOneWidget);
    expect(find.text('开始处理文件'), findsOneWidget);
    expect(find.text('查看任务记录'), findsOneWidget);
    expect(find.textContaining('本机处理'), findsWidgets);
  });

  testWidgets('home lists every registry tool as a shortcut', (tester) async {
    await _pumpHome(tester, InMemoryTaskRepository());

    for (final definition in kToolDefinitions) {
      expect(
        find.text(definition.name['zh']!),
        findsWidgets,
        reason: '首页快捷入口来自 registry：${definition.id}',
      );
    }
    expect(find.text('工具速用'), findsOneWidget);
  });

  testWidgets('empty task list shows a compact empty state', (tester) async {
    await _pumpHome(tester, InMemoryTaskRepository());

    expect(find.text('还没有任务'), findsOneWidget);
    expect(find.text('去选择工具'), findsOneWidget);
  });

  testWidgets('recent tasks show the file name and status', (tester) async {
    final repository = InMemoryTaskRepository();
    final at = DateTime.utc(2026, 1, 1);
    final queued = Task(
      taskId: 'task-1',
      idempotencyKey: 'key-1',
      toolId: 'png_to_jpeg',
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: at,
      updatedAt: at,
      attemptStartedAt: at,
      inputMetadata: const {'name': 'lecture.png'},
    );
    await repository.create(queued);
    await repository.update(queued.transitionTo(TaskStatus.running));
    final running = (await repository.listRecent()).single;
    await repository.update(
      running.transitionTo(
        TaskStatus.failed,
        error: const TaskError(code: 'write_failed', message: 'Disk full'),
      ),
    );

    await _pumpHome(tester, repository);

    expect(find.text('lecture.png'), findsOneWidget);
    expect(find.textContaining('失败'), findsOneWidget);
    expect(find.text('Disk full'), findsNothing);
  });

  testWidgets('narrow layout does not overflow', (tester) async {
    await _pumpHome(
      tester,
      InMemoryTaskRepository(),
      size: const Size(360, 900),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('文件处理，简单一点。'), findsOneWidget);
  });
}