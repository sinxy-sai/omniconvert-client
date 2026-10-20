import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/storage/database.dart';
import 'package:omniconvert/core/tasks/sqlite_task_repository.dart';
import 'package:omniconvert/core/tasks/task.dart';
import 'package:omniconvert/core/tasks/task_status.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);
  Task task(String id, {DateTime? at, String? key}) => Task(
    taskId: id,
    idempotencyKey: key ?? 'key-$id',
    toolId: 'image.compress',
    executionMode: ExecutionMode.local,
    status: TaskStatus.queued,
    createdAt: at ?? start,
    updatedAt: at ?? start,
    attemptStartedAt: at ?? start,
    inputMetadata: const {'name': 'notes.png', 'path': '/files/notes.png'},
  );

  test(
    'persists tasks, structured errors, ordering, and retry identity',
    () async {
      final database = TaskDatabase(sqlite3.openInMemory());
      addTearDown(database.close);
      final repository = SqliteTaskRepository(database);
      await repository.create(task('older'));
      await repository.create(
        task('newer', at: start.add(const Duration(days: 1))),
      );
      final running = task('older').transitionTo(
        TaskStatus.running,
        at: start.add(const Duration(days: 2)),
      );
      await repository.update(running);
      final failed = running.transitionTo(
        TaskStatus.failed,
        at: start.add(const Duration(days: 3)),
        error: const TaskError(code: 'disk_full', message: 'No space'),
      );
      await repository.update(failed);
      final recent = await repository.listRecent(limit: 1);
      expect(recent.single.taskId, 'older');
      expect(recent.single.error?.code, 'disk_full');
      expect(recent.single.inputMetadata['path'], '/files/notes.png');

      final retried = recent.single.transitionTo(
        TaskStatus.queued,
        at: start.add(const Duration(days: 4)),
      );
      await repository.update(retried);
      expect((await repository.listRecent()).first.idempotencyKey, 'key-older');
      expect((await repository.listRecent()).first.error, isNull);
    },
  );

  test('enforces a unique idempotency key', () async {
    final database = TaskDatabase(sqlite3.openInMemory());
    addTearDown(database.close);
    final repository = SqliteTaskRepository(database);
    await repository.create(task('first'));
    await expectLater(
      repository.create(task('second', key: 'key-first')),
      throwsStateError,
    );
  });

  test('restart changes only running tasks to interrupted', () async {
    final directory = await Directory.systemTemp.createTemp(
      'omniconvert-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}tasks.sqlite';

    var database = TaskDatabase(sqlite3.open(path));
    var repository = SqliteTaskRepository(database);
    await repository.create(task('running'));
    await repository.create(task('queued'));
    await repository.update(task('running').transitionTo(TaskStatus.running));
    database.close();

    database = TaskDatabase(sqlite3.open(path));
    addTearDown(database.close);
    repository = SqliteTaskRepository(database);
    await repository.markInterrupted();
    final tasks = await repository.listRecent();
    expect(
      tasks.singleWhere((item) => item.taskId == 'running').status,
      TaskStatus.interrupted,
    );
    expect(
      tasks.singleWhere((item) => item.taskId == 'queued').status,
      TaskStatus.queued,
    );
    expect(database.connection.userVersion, 1);
  });
}
