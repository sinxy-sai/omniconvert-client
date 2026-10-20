import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../storage/database.dart';
import 'task.dart';
import 'task_repository.dart';
import 'task_status.dart';

class SqliteTaskRepository implements TaskRepository {
  const SqliteTaskRepository(this.database);

  final TaskDatabase database;
  CommonDatabase get _db => database.connection;

  @override
  Future<void> create(Task task) async {
    if (task.status != TaskStatus.queued) {
      throw StateError('A new task must be queued.');
    }
    try {
      _db.execute('''
        INSERT INTO tasks (
          task_id, idempotency_key, tool_id, execution_mode, status,
          progress, created_at, updated_at, attempt_started_at,
          input_metadata, output_metadata, error_code, error_message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', _values(task));
    } on SqliteException catch (error) {
      if (error.extendedResultCode == 1555 ||
          error.extendedResultCode == 2067 ||
          error.resultCode == 19) {
        throw StateError('Task ID and idempotency key must be unique.');
      }
      rethrow;
    }
  }

  @override
  Future<void> update(Task task) async {
    final rows = _db.select('SELECT * FROM tasks WHERE task_id = ?', [
      task.taskId,
    ]);
    if (rows.isEmpty) throw StateError('Task does not exist.');
    validateTaskUpdate(_fromRow(rows.single), task);
    _db.execute(
      '''
      UPDATE tasks SET
        idempotency_key = ?, tool_id = ?, execution_mode = ?, status = ?,
        progress = ?, created_at = ?, updated_at = ?, attempt_started_at = ?,
        input_metadata = ?, output_metadata = ?, error_code = ?, error_message = ?
      WHERE task_id = ?
    ''',
      [..._values(task).skip(1), task.taskId],
    );
  }

  @override
  Future<List<Task>> listRecent({int limit = 20}) async {
    if (limit < 0) throw ArgumentError.value(limit, 'limit');
    final rows = _db.select(
      '''
      SELECT * FROM tasks ORDER BY updated_at DESC, task_id ASC LIMIT ?
    ''',
      [limit],
    );
    return List.unmodifiable(rows.map(_fromRow));
  }

  @override
  Future<void> markInterrupted() async {
    _db.execute(
      '''
      UPDATE tasks SET status = ?, updated_at = ? WHERE status = ?
    ''',
      [
        TaskStatus.interrupted.name,
        DateTime.now().toUtc().millisecondsSinceEpoch,
        TaskStatus.running.name,
      ],
    );
  }

  List<Object?> _values(Task task) => [
    task.taskId,
    task.idempotencyKey,
    task.toolId,
    task.executionMode.name,
    task.status.name,
    task.progress,
    task.createdAt.millisecondsSinceEpoch,
    task.updatedAt.millisecondsSinceEpoch,
    task.attemptStartedAt.millisecondsSinceEpoch,
    jsonEncode(task.inputMetadata),
    jsonEncode(task.outputMetadata),
    task.error?.code,
    task.error?.message,
  ];

  Task _fromRow(Row row) {
    DateTime timestamp(String key) =>
        DateTime.fromMillisecondsSinceEpoch(row[key] as int, isUtc: true);
    final errorCode = row['error_code'] as String?;
    return Task(
      taskId: row['task_id'] as String,
      idempotencyKey: row['idempotency_key'] as String,
      toolId: row['tool_id'] as String,
      executionMode: ExecutionMode.values.byName(
        row['execution_mode'] as String,
      ),
      status: TaskStatus.values.byName(row['status'] as String),
      progress: row['progress'] as double,
      createdAt: timestamp('created_at'),
      updatedAt: timestamp('updated_at'),
      attemptStartedAt: timestamp('attempt_started_at'),
      inputMetadata: Map<String, String>.from(
        jsonDecode(row['input_metadata'] as String) as Map,
      ),
      outputMetadata: Map<String, String>.from(
        jsonDecode(row['output_metadata'] as String) as Map,
      ),
      error: errorCode == null
          ? null
          : TaskError(
              code: errorCode,
              message: row['error_message'] as String? ?? '',
            ),
    );
  }
}
