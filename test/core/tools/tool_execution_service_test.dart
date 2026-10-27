import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tasks/task_repository.dart';
import 'package:omniconvert/core/tasks/task_status.dart';
import 'package:omniconvert/core/tools/tool_execution_service.dart';
import 'package:omniconvert/core/tools/tool_runner.dart';

class _FakeRunner implements ToolRunner {
  _FakeRunner({this.failure});

  final ToolRunFailure? failure;
  ToolRequest? lastRequest;

  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) async {
    lastRequest = request;
    onProgress?.call(const ToolProgress(stage: 'encoding', progress: 0.5));
    final error = failure;
    if (error != null) throw ToolRunException(error);
    return ToolRunResult(
      outputPath: request.outputPath,
      inputBytes: 12,
      outputBytes: 8,
      metadata: const {'width': '2', 'height': '1'},
    );
  }
}

class _BlockingRunner implements CancellableToolRunner {
  final result = Completer<ToolRunResult>();
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) => result.future;
}

ToolRequest _request() => const ToolRequest(
  toolId: 'png_to_jpeg',
  inputPath: r'C:\input.png',
  outputPath: r'C:\output.jpg',
  options: {'quality': '90'},
  maxBytes: 1024,
);

void main() {
  test('runs a local tool and persists the successful result', () async {
    final repository = InMemoryTaskRepository();
    final runner = _FakeRunner();
    final service = ToolExecutionService(repository, runner);

    final taskId = await service.execute(_request());
    final task = (await repository.listRecent()).single;

    expect(taskId, task.taskId);
    expect(task.status, TaskStatus.succeeded);
    expect(task.outputMetadata['path'], r'C:\output.jpg');
    expect(task.outputMetadata['bytes'], '8');
    expect(task.progress, 1);
    expect(runner.lastRequest, _request());
  });

  test('records a structured failure and keeps the task retryable', () async {
    final repository = InMemoryTaskRepository();
    final service = ToolExecutionService(
      repository,
      _FakeRunner(
        failure: const ToolRunFailure(
          code: 'InputTooLarge',
          message: 'Input exceeds the size limit',
        ),
      ),
    );

    await expectLater(
      service.execute(_request()),
      throwsA(isA<ToolRunException>()),
    );
    final taskId = (await repository.listRecent()).single.taskId;
    final task = (await repository.listRecent()).single;

    expect(taskId, task.taskId);
    expect(task.status, TaskStatus.failed);
    expect(task.error?.code, 'InputTooLarge');
    expect(task.error?.message, 'Input exceeds the size limit');
  });

  test('cancellation wins over a late successful runner result', () async {
    final repository = InMemoryTaskRepository();
    final runner = _BlockingRunner();
    final service = ToolExecutionService(repository, runner);
    final execution = await service.start(_request());

    await execution.cancel();
    runner.result.complete(
      ToolRunResult(
        outputPath: _request().outputPath,
        inputBytes: 12,
        outputBytes: 8,
      ),
    );
    await execution.completed;

    final task = (await repository.listRecent()).single;
    expect(runner.cancelled, isTrue);
    expect(task.status, TaskStatus.cancelled);
    expect(task.outputMetadata, isEmpty);
  });
}
