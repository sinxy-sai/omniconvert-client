import 'dart:math';

import '../tasks/task.dart';
import '../tasks/task_repository.dart';
import '../tasks/task_status.dart';
import 'tool_runner.dart';

class ToolExecutionService {
  ToolExecutionService(this.repository, this.runner);

  final TaskRepository repository;
  final ToolRunner runner;

  Future<String> execute(ToolRequest request) async {
    final now = DateTime.now().toUtc();
    final taskId = '${request.toolId}-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    final task = Task(
      taskId: taskId,
      idempotencyKey: taskId,
      toolId: request.toolId,
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: now,
      updatedAt: now,
      attemptStartedAt: now,
      inputMetadata: {'path': request.inputPath, 'name': request.inputPath.split(RegExp(r'[\\/]')).last},
    );
    await repository.create(task);
    var current = task.transitionTo(TaskStatus.running);
    await repository.update(current);
    var progressWrite = Future<void>.value();
    try {
      final result = await runner.run(request, onProgress: (progress) {
        if (current.status == TaskStatus.running && progress.progress >= current.progress) {
          current = current.withProgress(progress.progress);
          progressWrite = progressWrite.then((_) => repository.update(current));
        }
      });
      await progressWrite;
      current = current.transitionTo(TaskStatus.succeeded, outputMetadata: {
        'path': result.outputPath,
        'bytes': '${result.outputBytes}',
        ...result.metadata,
      });
      await repository.update(current);
    } on ToolRunException catch (error) {
      current = current.transitionTo(TaskStatus.failed, error: TaskError(
        code: error.failure.code,
        message: error.failure.message,
      ));
      await repository.update(current);
      rethrow;
    }
    return taskId;
  }
}
