import 'package:flutter/material.dart';

import '../../../app/icons/oc_icons.dart';
import '../../../app/navigation.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../app/widgets/inline_alert.dart';
import '../../../app/widgets/page_layout.dart';
import '../../../app/widgets/skeleton.dart';
import '../../../app/widgets/surface_card.dart';
import '../../../app/widgets/task_row.dart';
import '../../../app/widgets/tone.dart';
import '../../../core/tasks/task.dart';
import '../../../core/tasks/task_repository.dart';
import '../../../core/tasks/task_status.dart';

/// 任务页：按状态分组，失败的原始信息放在可展开的详情里。
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

enum _Filter { all, active, done, issue }

class _TasksPageState extends State<TasksPage> {
  late Future<List<Task>> _tasks = widget.repository.listRecent();
  _Filter _filter = _Filter.all;

  void _refresh() =>
      setState(() => _tasks = widget.repository.listRecent());

  void _openTools() =>
      Navigator.of(context).pushReplacementNamed(AppSection.tools.path);

  List<Task> _visible(List<Task> tasks) => switch (_filter) {
    _Filter.all => tasks,
    _Filter.active => tasks
        .where(
          (task) =>
              task.status == TaskStatus.running ||
              task.status == TaskStatus.queued,
        )
        .toList(),
    _Filter.done => tasks
        .where((task) => task.status == TaskStatus.succeeded)
        .toList(),
    _Filter.issue => tasks
        .where(
          (task) =>
              task.status == TaskStatus.failed ||
              task.status == TaskStatus.cancelled ||
              task.status == TaskStatus.interrupted,
        )
        .toList(),
  };

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      children: [
        PageHeader(
          eyebrow: '任务',
          title: '任务记录',
          description: '转换与压缩的记录保存在本机；展开每条可以看路径、耗时和错误码。',
          trailing: IconButton(
            onPressed: _refresh,
            tooltip: '刷新任务记录',
            icon: const OcIcon(OcIcons.refresh, size: 18),
          ),
        ),
        vgap(OcSpace.md),
        _FilterBar(
          current: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        vgap(OcSpace.sm),
        FutureBuilder<List<Task>>(
          future: _tasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return InlineAlert(
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
              return const SurfaceCard(
                padding: EdgeInsets.all(OcSpace.md),
                child: SkeletonLines(lines: 4),
              );
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) {
              return EmptyStatePanel(
                icon: OcIcons.tasks,
                title: '还没有任务',
                description: '处理一个文件之后，这里会按状态列出结果，方便回头确认。',
                action: FilledButton.icon(
                  onPressed: _openTools,
                  icon: const OcIcon(OcIcons.arrowRight, size: 16),
                  label: const Text('去选择工具'),
                ),
              );
            }
            final visible = _visible(tasks);
            if (visible.isEmpty) {
              return EmptyStatePanel(
                icon: OcIcons.list,
                title: '这个筛选下没有任务',
                description: '换一个筛选条件，或者回到全部任务看看。',
                action: TextButton(
                  onPressed: () => setState(() => _filter = _Filter.all),
                  child: const Text('查看全部任务'),
                ),
              );
            }
            final groups = _grouped(visible);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < groups.length; index++) ...[
                  if (index > 0) vgap(OcSpace.sm),
                  _TaskGroupCard(group: groups[index]),
                ],
              ],
            );
          },
        ),
        vgap(OcSpace.xl),
      ],
    );
  }

  List<_TaskGroup> _grouped(List<Task> tasks) => <_TaskGroup>[
    _TaskGroup(
      title: '进行中',
      tone: OcTone.brand,
      icon: OcIcons.refresh,
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
      icon: OcIcons.check,
      tasks: tasks
          .where((task) => task.status == TaskStatus.succeeded)
          .toList(),
    ),
    _TaskGroup(
      title: '未完成',
      tone: OcTone.danger,
      icon: OcIcons.alert,
      tasks: tasks
          .where(
            (task) =>
                task.status == TaskStatus.failed ||
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
  final OcIconData icon;
  final List<Task> tasks;
}

class _TaskGroupCard extends StatelessWidget {
  const _TaskGroupCard({required this.group});

  final _TaskGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        OcSpace.sm,
        OcSpace.sm,
        OcSpace.sm,
        OcSpace.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusPill(
                label: group.title,
                tone: group.tone,
                icon: group.icon,
                dense: true,
              ),
              const SizedBox(width: OcSpace.xs),
              Text(
                '${group.tasks.length} 条',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: OcSpace.xxs),
          for (var index = 0; index < group.tasks.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: scheme.outlineVariant),
            TaskRow(task: group.tasks[index], showStatus: true),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});

  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <(_Filter, String)>[
      (_Filter.all, '全部'),
      (_Filter.active, '进行中'),
      (_Filter.done, '已完成'),
      (_Filter.issue, '未完成'),
    ];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: OcSpace.xs,
      runSpacing: OcSpace.xs,
      children: [
        for (final (filter, label) in labels)
          Semantics(
            button: true,
            selected: filter == current,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(filter),
              borderRadius: BorderRadius.circular(OcRadius.pill),
              child: AnimatedContainer(
                duration: OcDuration.fast,
                curve: OcDuration.curve,
                padding: const EdgeInsets.symmetric(
                  horizontal: OcSpace.sm,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: filter == current
                      ? scheme.primaryContainer
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(OcRadius.pill),
                  border: Border.all(
                    color: filter == current
                        ? scheme.primary.withValues(alpha: 0.35)
                        : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: filter == current
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}