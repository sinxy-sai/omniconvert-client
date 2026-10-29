import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/oc_page.dart';
import '../../../app/widgets/oc_surface.dart';
import '../../../app/widgets/task_card.dart';
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
  Widget build(BuildContext context) {
    return OcPage(
      children: [
        OcPageHeader(
          title: '任务记录',
          description: '转换与压缩的记录保存在本机；按状态分组，方便确认处理结果。',
          trailing: IconButton(
            onPressed: _refresh,
            tooltip: '刷新任务记录',
            icon: const Icon(Icons.refresh_rounded),
          ),
          trailingWide: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('刷新'),
          ),
        ),
        const SizedBox(height: OcSpace.lg),
        FutureBuilder<List<Task>>(
          future: _tasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return OcNotice(
                tone: OcTone.danger,
                title: '任务记录暂时无法读取',
                message: '可以刷新重试；已经写入磁盘的文件不会丢失。',
                action: OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('刷新'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return OcCard(
                padding: const EdgeInsets.all(OcSpace.lg),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: OcSpace.sm),
                    Text(
                      '正在读取任务记录…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) {
              return OcCard(
                child: OcEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: '暂无任务',
                  description: '还没有任务记录。选择一个工具处理文件，完成后会自动出现在这里。',
                  action: FilledButton.icon(
                    onPressed: () => ocNavigate(context, '/tools'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('去选择工具'),
                  ),
                ),
              );
            }
            final groups = _groupTasks(tasks);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0) const SizedBox(height: OcSpace.lg),
                  _GroupHeader(group: groups[i]),
                  const SizedBox(height: OcSpace.sm),
                  for (var j = 0; j < groups[i].tasks.length; j++) ...[
                    if (j > 0) const SizedBox(height: OcSpace.sm),
                    TaskCard(task: groups[i].tasks[j], showStatus: false),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<_TaskGroup> _groupTasks(List<Task> tasks) => <_TaskGroup>[
    _TaskGroup(
      title: '进行中',
      tone: OcTone.brand,
      icon: Icons.autorenew_rounded,
      tasks: tasks
          .where(
            (task) =>
                task.status == TaskStatus.running ||
                task.status == TaskStatus.queued,
          )
          .toList(),
    ),
    _TaskGroup(
      title: '已完成',
      tone: OcTone.success,
      icon: Icons.check_circle_outline_rounded,
      tasks: tasks
          .where((task) => task.status == TaskStatus.succeeded)
          .toList(),
    ),
    _TaskGroup(
      title: '失败',
      tone: OcTone.danger,
      icon: Icons.error_outline_rounded,
      tasks: tasks.where((task) => task.status == TaskStatus.failed).toList(),
    ),
    _TaskGroup(
      title: '未完成',
      tone: OcTone.neutral,
      icon: Icons.remove_circle_outline_rounded,
      tasks: tasks
          .where(
            (task) =>
                task.status == TaskStatus.cancelled ||
                task.status == TaskStatus.interrupted,
          )
          .toList(),
    ),
  ].where((group) => group.tasks.isNotEmpty).toList();
}

class _TaskGroup {
  const _TaskGroup({
    required this.title,
    required this.tone,
    required this.icon,
    required this.tasks,
  });

  final String title;
  final OcTone tone;
  final IconData icon;
  final List<Task> tasks;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _TaskGroup group;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        OcPill(label: group.title, tone: group.tone, dense: true, icon: group.icon),
        const SizedBox(width: OcSpace.xs),
        Text('${group.tasks.length} 个任务', style: textTheme.bodySmall),
      ],
    );
  }
}