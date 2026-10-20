import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/tasks/task_repository_factory_native.dart'
    if (dart.library.js_interop) 'core/tasks/task_repository_factory_web.dart'
    as task_repository_factory;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await task_repository_factory.createTaskRepository();
  await repository.markInterrupted();
  runApp(OmniConvertApp(taskRepository: repository));
}
