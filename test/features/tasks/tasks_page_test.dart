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

    await tester.pumpWidget(
      MaterialApp(home: TasksPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('photo.png'), findsOneWidget);
    expect(find.textContaining('失败'), findsOneWidget);
    expect(find.text('Disk full'), findsOneWidget);
  });
}
