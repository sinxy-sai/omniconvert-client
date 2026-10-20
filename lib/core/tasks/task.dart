import 'task_status.dart';

enum ExecutionMode { local, selfHosted, officialCloud }

class TaskError {
  const TaskError({required this.code, required this.message});

  final String code;
  final String message;
}

class Task {
  Task({
    required this.taskId,
    required this.idempotencyKey,
    required this.toolId,
    required this.executionMode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.attemptStartedAt,
    this.progress = 0,
    Map<String, String> inputMetadata = const {},
    Map<String, String> outputMetadata = const {},
    this.error,
  }) : inputMetadata = Map.unmodifiable(inputMetadata),
       outputMetadata = Map.unmodifiable(outputMetadata) {
    if (taskId.isEmpty || idempotencyKey.isEmpty || toolId.isEmpty) {
      throw ArgumentError('Task identifiers must not be empty.');
    }
    if (!progress.isFinite || progress < 0 || progress > 1) {
      throw ArgumentError.value(
        progress,
        'progress',
        'Must be between 0 and 1.',
      );
    }
    if (updatedAt.isBefore(createdAt) || attemptStartedAt.isBefore(createdAt)) {
      throw ArgumentError('Task timestamps must not precede creation.');
    }
  }

  final String taskId;
  final String idempotencyKey;
  final String toolId;
  final ExecutionMode executionMode;
  final TaskStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime attemptStartedAt;
  final Map<String, String> inputMetadata;
  final Map<String, String> outputMetadata;
  final TaskError? error;

  Task transitionTo(
    TaskStatus next, {
    DateTime? at,
    TaskError? error,
    Map<String, String>? outputMetadata,
  }) {
    if (!status.canTransitionTo(next)) {
      throw StateError('Invalid task transition: $status → $next');
    }
    if (next == TaskStatus.failed && error == null) {
      throw ArgumentError('A failed task requires a structured error.');
    }
    final changedAt = (at ?? DateTime.now()).toUtc();
    if (changedAt.isBefore(updatedAt)) {
      throw ArgumentError('A transition cannot move backwards in time.');
    }
    return Task(
      taskId: taskId,
      idempotencyKey: idempotencyKey,
      toolId: toolId,
      executionMode: executionMode,
      status: next,
      progress: switch (next) {
        TaskStatus.queued => 0,
        TaskStatus.succeeded => 1,
        _ => progress,
      },
      createdAt: createdAt,
      updatedAt: changedAt,
      attemptStartedAt: next == TaskStatus.queued
          ? changedAt
          : attemptStartedAt,
      inputMetadata: inputMetadata,
      outputMetadata:
          outputMetadata ??
          (next == TaskStatus.queued ? const {} : this.outputMetadata),
      error: next == TaskStatus.failed ? error : null,
    );
  }

  Task withProgress(double nextProgress, {DateTime? at}) {
    if (status != TaskStatus.running) {
      throw StateError('Progress can only change while a task is running.');
    }
    final changedAt = (at ?? DateTime.now()).toUtc();
    if (changedAt.isBefore(updatedAt)) {
      throw ArgumentError('Progress cannot move backwards in time.');
    }
    if (nextProgress < progress) {
      throw ArgumentError('Progress cannot decrease during an attempt.');
    }
    return Task(
      taskId: taskId,
      idempotencyKey: idempotencyKey,
      toolId: toolId,
      executionMode: executionMode,
      status: status,
      progress: nextProgress,
      createdAt: createdAt,
      updatedAt: changedAt,
      attemptStartedAt: attemptStartedAt,
      inputMetadata: inputMetadata,
      outputMetadata: outputMetadata,
      error: error,
    );
  }
}
