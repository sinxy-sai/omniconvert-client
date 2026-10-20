import 'package:sqlite3/wasm.dart';

import '../storage/database.dart';
import 'sqlite_task_repository.dart';
import 'task_repository.dart';

Future<TaskRepository> createTaskRepository() async {
  final sqlite = await WasmSqlite3.loadFromUrlString('sqlite3.wasm');
  final fileSystem = await IndexedDbFileSystem.open(
    dbName: 'omniconvert-tasks',
  );
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return SqliteTaskRepository(TaskDatabase(sqlite.open('tasks.sqlite')));
}
