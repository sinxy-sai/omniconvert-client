import 'task.dart';
import 'task_status.dart';

abstract interface class TaskRepository {
  Future<void> create(Task task);
  Future<void> update(Task task);
  Future<List<Task>> listRecent({int limit = 20});
  Future<void> markInterrupted();
}

void validateTaskUpdate(Task previous, Task next) {
  if (previous.taskId != next.taskId ||
      previous.idempotencyKey != next.idempotencyKey ||
      previous.toolId != next.toolId ||
      previous.executionMode != next.executionMode ||
      previous.createdAt != next.createdAt ||
      next.updatedAt.isBefore(previous.updatedAt)) {
    throw StateError('Task identity or timestamp changed unexpectedly.');
  }
  if (previous.status == next.status) {
    if (next.status != TaskStatus.running ||
        next.progress < previous.progress) {
      throw StateError('Only running task progress may be updated in place.');
    }
  } else if (!previous.status.canTransitionTo(next.status)) {
    throw StateError('Invalid persisted task transition.');
  }
}

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};

  @override
  Future<void> create(Task task) async {
    if (task.status != TaskStatus.queued ||
        _tasks.containsKey(task.taskId) ||
        _tasks.values.any(
          (existing) => existing.idempotencyKey == task.idempotencyKey,
        )) {
      throw StateError('Task must be new, queued, and have a unique identity.');
    }
    _tasks[task.taskId] = task;
  }

  @override
  Future<void> update(Task task) async {
    final previous = _tasks[task.taskId];
    if (previous == null) throw StateError('Task does not exist.');
    validateTaskUpdate(previous, task);
    _tasks[task.taskId] = task;
  }

  @override
  Future<List<Task>> listRecent({int limit = 20}) async {
    if (limit < 0) throw ArgumentError.value(limit, 'limit');
    final sorted = _tasks.values.toList()
      ..sort((a, b) {
        final byTime = b.updatedAt.compareTo(a.updatedAt);
        return byTime != 0 ? byTime : a.taskId.compareTo(b.taskId);
      });
    return List.unmodifiable(sorted.take(limit));
  }

  @override
  Future<void> markInterrupted() async {
    for (final task in _tasks.values.toList()) {
      if (task.status == TaskStatus.running) {
        _tasks[task.taskId] = task.transitionTo(TaskStatus.interrupted);
      }
    }
  }
}
