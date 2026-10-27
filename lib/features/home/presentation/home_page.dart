import 'package:flutter/material.dart';

import '../../../core/tasks/task.dart';
import '../../../core/tasks/task_repository.dart';
import '../../../core/tasks/task_status.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.taskRepository});

  final TaskRepository taskRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Task>> _recentTasks = widget.taskRepository
      .listRecent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('继续你的工作', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('文件处理默认在本机完成。选择工具后，任务会显示在这里。'),
        const SizedBox(height: 28),
        Text('快速操作', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickAction(
              icon: Icons.functions,
              title: '公式识别',
              subtitle: '手写公式转 LaTeX',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/formula'),
            ),
            _QuickAction(
              icon: Icons.swap_horiz,
              title: '文件转换',
              subtitle: '图片与文档格式',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/tools'),
            ),
            _QuickAction(
              icon: Icons.compress,
              title: '图片压缩',
              subtitle: '控制尺寸与质量',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/tools'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('最近任务', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        FutureBuilder<List<Task>>(
          future: _recentTasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('任务记录暂时无法读取。');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) return _EmptyTasks(textTheme: textTheme);
            return Column(
              children: [
                for (final task in tasks)
                  Card.outlined(
                    child: ListTile(
                      title: Text(task.inputMetadata['name'] ?? task.toolId),
                      subtitle: Text('${task.toolId} · ${task.status.label}'),
                      trailing: null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.textTheme});
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('还没有任务', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('开始处理文件后，可以从这里继续查看结果。'),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Card.outlined(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    ),
  );
}
