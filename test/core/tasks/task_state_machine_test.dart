import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_status.dart';

void main() {
  final created = DateTime.utc(2026, 1, 1);
  final later = DateTime.utc(2026, 1, 2);

  Task queued() => Task(
    taskId: 'task-1',
    idempotencyKey: 'same-operation-1',
    toolId: 'image.png-to-jpeg',
    executionMode: ExecutionMode.local,
    status: TaskStatus.queued,
    createdAt: created,
    updatedAt: created,
    attemptStartedAt: created,
    inputMetadata: const {'name': 'figure.png'},
  );

  test('running succeeds with the same identity and result metadata', () {
    final running = queued().transitionTo(TaskStatus.running, at: later);
    final succeeded = running.transitionTo(
      TaskStatus.succeeded,
      at: later.add(const Duration(minutes: 1)),
      outputMetadata: const {'path': 'figure.jpeg'},
    );
    expect(succeeded.status, TaskStatus.succeeded);
    expect(succeeded.progress, 1);
    expect(succeeded.taskId, 'task-1');
    expect(succeeded.outputMetadata['path'], 'figure.jpeg');
  });

  test('running can fail with a structured error and retry explicitly', () {
    final running = queued().transitionTo(TaskStatus.running, at: later);
    final failed = running.transitionTo(
      TaskStatus.failed,
      at: later.add(const Duration(minutes: 1)),
      error: const TaskError(code: 'invalid_input', message: 'Invalid image'),
    );
    final retried = failed.transitionTo(
      TaskStatus.queued,
      at: later.add(const Duration(minutes: 2)),
    );
    expect(retried.taskId, failed.taskId);
    expect(retried.idempotencyKey, failed.idempotencyKey);
    expect(retried.attemptStartedAt, later.add(const Duration(minutes: 2)));
    expect(retried.error, isNull);
    expect(retried.progress, 0);
  });

  test('running can be cancelled or marked interrupted', () {
    final running = queued().transitionTo(TaskStatus.running, at: later);
    expect(
      running.transitionTo(TaskStatus.cancelled).status,
      TaskStatus.cancelled,
    );
    final interrupted = running.transitionTo(TaskStatus.interrupted);
    expect(
      interrupted.transitionTo(TaskStatus.queued).status,
      TaskStatus.queued,
    );
  });

  test('other transitions are rejected', () {
    for (final status in TaskStatus.values) {
      final task = status == TaskStatus.queued
          ? queued()
          : queued().transitionTo(TaskStatus.running);
      if (status != TaskStatus.queued && status != TaskStatus.running) {
        continue;
      }
      for (final next in TaskStatus.values) {
        if (status.canTransitionTo(next)) continue;
        expect(
          () => task.transitionTo(next),
          throwsStateError,
          reason: '$status to $next',
        );
      }
    }
    final succeeded = queued()
        .transitionTo(TaskStatus.running)
        .transitionTo(TaskStatus.succeeded);
    expect(() => succeeded.transitionTo(TaskStatus.queued), throwsStateError);
  });

  test('task metadata is immutable and progress must be valid', () {
    final task = queued();
    expect(
      () => task.inputMetadata['name'] = 'changed',
      throwsUnsupportedError,
    );
    expect(
      () => task.transitionTo(TaskStatus.running).withProgress(1.1),
      throwsArgumentError,
    );
  });
}
