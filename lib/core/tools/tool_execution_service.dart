import 'dart:async';
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
    final execution = await start(request);
    return execution.completed;
  }

  Future<ToolExecution> start(ToolRequest request) async {
    final now = DateTime.now().toUtc();
    final taskId =
        '${request.toolId}-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    final queued = Task(
      taskId: taskId,
      idempotencyKey: taskId,
      toolId: request.toolId,
      executionMode: ExecutionMode.local,
      status: TaskStatus.queued,
      createdAt: now,
      updatedAt: now,
      attemptStartedAt: now,
      inputMetadata: {
        'path': request.inputPath,
        'name': request.inputPath.split(RegExp(r'[\\/]')).last,
      },
    );
    await repository.create(queued);
    var current = queued.transitionTo(TaskStatus.running);
    await repository.update(current);
    var cancelled = false;
    var progressWrite = Future<void>.value();
    final resultCompleter = Completer<ToolRunResult?>();

    final completion = () async {
      try {
        final result = await runner.run(
          request,
          onProgress: (progress) {
            if (!cancelled &&
                current.status == TaskStatus.running &&
                progress.progress >= current.progress) {
              final progressed = current.withProgress(progress.progress);
              current = progressed;
              progressWrite = progressWrite.then(
                (_) => repository.update(progressed),
              );
            }
          },
        );
        await progressWrite;
        if (cancelled || current.status == TaskStatus.cancelled) {
          resultCompleter.complete(null);
          return taskId;
        }
        current = current.transitionTo(
          TaskStatus.succeeded,
          outputMetadata: {
            'path': result.outputPath,
            'bytes': '${result.outputBytes}',
            ...result.metadata,
          },
        );
        await repository.update(current);
        resultCompleter.complete(result);
      } on ToolRunException catch (error) {
        await progressWrite;
        if (cancelled || current.status == TaskStatus.cancelled) {
          resultCompleter.complete(null);
          return taskId;
        }
        current = current.transitionTo(
          TaskStatus.failed,
          error: TaskError(
            code: error.failure.code,
            message: error.failure.message,
          ),
        );
        await repository.update(current);
        resultCompleter.complete(null);
        rethrow;
      }
      return taskId;
    }();

    return ToolExecution(
      taskId: taskId,
      completed: completion,
      result: resultCompleter.future,
      isCancelledCallback: () => cancelled,
      cancelCallback: () async {
        if (cancelled || current.status != TaskStatus.running) return;
        cancelled = true;
        if (runner case final CancellableToolRunner cancellable) {
          cancellable.cancel();
        }
        current = current.transitionTo(TaskStatus.cancelled);
        await repository.update(current);
      },
    );
  }
}

class ToolExecution {
  const ToolExecution({
    required this.taskId,
    required this.completed,
    required this.result,
    required this.isCancelledCallback,
    required this.cancelCallback,
  });

  final String taskId;
  final Future<String> completed;
  final Future<ToolRunResult?> result;
  final bool Function() isCancelledCallback;
  final Future<void> Function() cancelCallback;

  bool get isCancelled => isCancelledCallback();

  Future<void> cancel() => cancelCallback();
}

abstract interface class CancellableToolRunner implements ToolRunner {
  void cancel();
}
