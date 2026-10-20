import 'package:sqlite3/common.dart';

class TaskDatabase {
  TaskDatabase(this.connection) {
    _migrate();
  }

  final CommonDatabase connection;

  void _migrate() {
    final version = connection.userVersion;
    if (version > 1) {
      throw StateError('This task database needs a newer OmniConvert client.');
    }
    if (version == 1) return;

    connection.execute('BEGIN IMMEDIATE');
    try {
      connection.execute('''
        CREATE TABLE tasks (
          task_id TEXT PRIMARY KEY NOT NULL,
          idempotency_key TEXT NOT NULL UNIQUE,
          tool_id TEXT NOT NULL,
          execution_mode TEXT NOT NULL,
          status TEXT NOT NULL,
          progress REAL NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          attempt_started_at INTEGER NOT NULL,
          input_metadata TEXT NOT NULL,
          output_metadata TEXT NOT NULL,
          error_code TEXT,
          error_message TEXT
        ) STRICT
      ''');
      connection.execute(
        'CREATE INDEX tasks_updated_at_idx ON tasks(updated_at DESC)',
      );
      connection.userVersion = 1;
      connection.execute('COMMIT');
    } catch (_) {
      connection.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => connection.close();
}
