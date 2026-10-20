import 'package:flutter/material.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('任务记录', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Card.outlined(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('暂无任务。完成处理后，结果会显示在这里。'),
        ),
      ),
    ],
  );
}
