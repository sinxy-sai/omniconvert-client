import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/app.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tasks/task_status.dart';

void main() {
  testWidgets('a guest can move between recent tasks, tools, and settings', (
    tester,
  ) async {
    await tester.pumpWidget(const OmniConvertApp());
    await tester.pumpAndSettle();

    expect(find.text('还没有任务'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-tools')));
    await tester.pumpAndSettle();
    expect(find.text('选择工具'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-settings')));
    await tester.pumpAndSettle();
    expect(find.text('本地工具无需登录'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('任务记录'), findsOneWidget);
  });

  testWidgets('recent failed task can be retried from home', (tester) async {
    final repository = InMemoryTaskRepository();
    final created = DateTime.utc(2026, 1, 1);
    final task = Task(
      taskId: 'image-1',
      idempotencyKey: 'image-key-1',
      toolId: 'image.compress',
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: created,
      updatedAt: created,
      attemptStartedAt: created,
      inputMetadata: const {'name': 'lecture.png'},
    );
    await repository.create(task);
    await repository.update(task.transitionTo(TaskStatus.running));
    final running = (await repository.listRecent()).single;
    await repository.update(
      running.transitionTo(
        TaskStatus.failed,
        error: const TaskError(code: 'write_failed', message: 'Disk full'),
      ),
    );

    await tester.pumpWidget(OmniConvertApp(taskRepository: repository));
    await tester.pumpAndSettle();
    expect(find.text('lecture.png'), findsOneWidget);
    expect(find.textContaining('失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-image-1')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect((await repository.listRecent()).single.status, TaskStatus.queued);
    expect(find.textContaining('等待中'), findsOneWidget);
  });
}
