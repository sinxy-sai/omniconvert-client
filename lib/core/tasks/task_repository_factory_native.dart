import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../storage/database.dart';
import 'sqlite_task_repository.dart';
import 'task_repository.dart';

Future<TaskRepository> createTaskRepository() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final path = '${directory.path}${Platform.pathSeparator}tasks.sqlite';
  return SqliteTaskRepository(TaskDatabase(sqlite3.open(path)));
}
