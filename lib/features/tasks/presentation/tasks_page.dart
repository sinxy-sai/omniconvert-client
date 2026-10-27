import 'package:flutter/material.dart';

import '../../../core/tasks/task.dart';
import '../../../core/tasks/task_repository.dart';
import '../../../core/tasks/task_status.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<List<Task>> _tasks = widget.repository.listRecent();

  void _refresh() => setState(() => _tasks = widget.repository.listRecent());

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '任务记录',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新任务记录',
          ),
        ],
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<Task>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('任务记录暂时无法读取。');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Card.outlined(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无任务。完成处理后，结果会显示在这里。'),
              ),
            );
          }
          return Column(
            children: [for (final task in tasks) _TaskCard(task: task)],
          );
        },
      ),
    ],
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final output = task.outputMetadata['path'];
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.inputMetadata['name'] ?? task.toolId,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('${task.toolId} · ${task.status.label}'),
            if (task.status == TaskStatus.running)
              LinearProgressIndicator(value: task.progress),
            if (output != null) Text('输出：$output'),
            if (task.error case final error?) Text(error.message),
          ],
        ),
      ),
    );
  }
}
