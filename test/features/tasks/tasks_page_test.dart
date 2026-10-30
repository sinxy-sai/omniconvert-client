import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tasks/task_status.dart';
import 'package:omniconvert/features/tasks/presentation/tasks_page.dart';

void main() {
  testWidgets('shows persisted task details from the repository', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 1, 1);
    final queued = Task(
      taskId: 'task-1',
      idempotencyKey: 'key-task-1',
      toolId: 'png_to_jpeg',
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: at,
      updatedAt: at,
      attemptStartedAt: at,
      inputMetadata: const {'name': 'photo.png'},
    );
    final repository = InMemoryTaskRepository();
    await repository.create(queued);
    await repository.update(queued.transitionTo(TaskStatus.running));
    final running = (await repository.listRecent()).single;
    await repository.update(
      running.transitionTo(
        TaskStatus.failed,
        error: const TaskError(code: 'write_failed', message: 'Disk full'),
      ),
    );

    // 这个页面设计上嵌在 AppShell 的 Scaffold 里：InkWell / ExpansionTile
    // 都需要 Material 祖先，所以测试必须按真实挂载方式套一层 Scaffold。
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TasksPage(repository: repository))),
    );
    await tester.pumpAndSettle();

    // 收起状态：文件名 + 状态可见，技术细节默认折叠。
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.textContaining('失败'), findsOneWidget);
    expect(find.text('Disk full'), findsNothing);

    // 展开任务行 → 给出可读的失败原因。
    await tester.tap(find.text('photo.png'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无法写入输出文件'), findsOneWidget);

    // 再展开「技术详情」才看到原始英文信息与错误码。
    await tester.tap(find.text('技术详情（反馈问题时请附上）'));
    await tester.pumpAndSettle();
    expect(find.text('错误码：write_failed'), findsOneWidget);
    expect(find.text('Disk full'), findsOneWidget);
  });
}