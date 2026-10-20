enum TaskStatus { queued, running, succeeded, failed, cancelled, interrupted }

extension TaskStatusRules on TaskStatus {
  bool canTransitionTo(TaskStatus next) => switch (this) {
    TaskStatus.queued => next == TaskStatus.running,
    TaskStatus.running =>
      next == TaskStatus.succeeded ||
          next == TaskStatus.failed ||
          next == TaskStatus.cancelled ||
          next == TaskStatus.interrupted,
    TaskStatus.failed || TaskStatus.interrupted => next == TaskStatus.queued,
    TaskStatus.succeeded || TaskStatus.cancelled => false,
  };

  String get label => switch (this) {
    TaskStatus.queued => '等待中',
    TaskStatus.running => '处理中',
    TaskStatus.succeeded => '已完成',
    TaskStatus.failed => '失败',
    TaskStatus.cancelled => '已取消',
    TaskStatus.interrupted => '已中断',
  };
}
