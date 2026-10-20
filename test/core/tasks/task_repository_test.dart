import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tasks/task_status.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);
  Task task(String id, {DateTime? at}) => Task(
    taskId: id,
    idempotencyKey: 'key-$id',
    toolId: 'image.compress',
    executionMode: ExecutionMode.local,
    status: TaskStatus.queued,
    createdAt: at ?? start,
    updatedAt: at ?? start,
    attemptStartedAt: at ?? start,
  );

  test('stores newest tasks first and interrupts only running work', () async {
    final repository = InMemoryTaskRepository();
    await repository.create(task('older'));
    await repository.create(
      task('newer', at: start.add(const Duration(days: 1))),
    );
    await repository.update(
      task('older').transitionTo(
        TaskStatus.running,
        at: start.add(const Duration(days: 2)),
      ),
    );
    await repository.markInterrupted();
    final recent = await repository.listRecent(limit: 1);
    expect(recent.single.taskId, 'older');
    expect(recent.single.status, TaskStatus.interrupted);
    expect((await repository.listRecent())[1].status, TaskStatus.queued);
  });

  test('rejects duplicate identity and invalid persisted transition', () async {
    final repository = InMemoryTaskRepository();
    await repository.create(task('first'));
    await expectLater(repository.create(task('first')), throwsStateError);
    final duplicateKey = Task(
      taskId: 'second',
      idempotencyKey: 'key-first',
      toolId: 'image.compress',
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: start,
      updatedAt: start,
      attemptStartedAt: start,
    );
    await expectLater(repository.create(duplicateKey), throwsStateError);
    final forged = Task(
      taskId: 'first',
      idempotencyKey: 'key-first',
      toolId: 'image.compress',
      executionMode: ExecutionMode.local,
      status: TaskStatus.succeeded,
      createdAt: start,
      updatedAt: start,
      attemptStartedAt: start,
      progress: 1,
    );
    await expectLater(repository.update(forged), throwsStateError);
  });
}
