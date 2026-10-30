import 'package:flutter/material.dart';

import '../error_text.dart';
import '../format.dart';
import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import '../tools/tool_display.dart';
import '../../core/tasks/task.dart';
import '../../core/tasks/task_status.dart';
import 'inline_alert.dart';
import 'surface_card.dart';
import 'tone.dart';

OcTone taskStatusTone(TaskStatus status) => switch (status) {
  TaskStatus.queued || TaskStatus.running => OcTone.brand,
  TaskStatus.succeeded => OcTone.success,
  TaskStatus.failed => OcTone.danger,
  TaskStatus.cancelled => OcTone.neutral,
  TaskStatus.interrupted => OcTone.warning,
};

OcIconData taskStatusIcon(TaskStatus status) => switch (status) {
  TaskStatus.queued => OcIcons.clock,
  TaskStatus.running => OcIcons.refresh,
  TaskStatus.succeeded => OcIcons.check,
  TaskStatus.failed => OcIcons.alert,
  TaskStatus.cancelled => OcIcons.stop,
  TaskStatus.interrupted => OcIcons.alert,
};

/// 一条任务记录：可折叠的详情行。
///
/// 收起时只给「文件名 + 工具 + 时间 + 状态」；
/// 展开后才给路径、耗时、错误码等排查信息。
class TaskRow extends StatefulWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.initiallyExpanded = false,
    this.showStatus = true,
  });

  final Task task;
  final bool initiallyExpanded;
  final bool showStatus;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tone = taskStatusTone(task.status);
    final colors = tone.resolve(context);
    final fileName = task.inputMetadata['name'] ?? toolNameFor(task.toolId);
    final meta = [
      toolNameFor(task.toolId),
      formatRelativeTime(task.updatedAt),
      if (task.outputMetadata['bytes'] != null)
        formatFileSize(int.tryParse(task.outputMetadata['bytes']!) ?? 0),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: '$fileName，${task.status.label}',
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(OcRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OcSpace.xs,
                vertical: OcSpace.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: colors.border),
                    ),
                    child: OcIcon(
                      toolIconFor(task.toolId),
                      size: 17,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(width: OcSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonoText(
                          fileName,
                          fontSize: 13.5,
                          weight: FontWeight.w600,
                          maxLines: 1,
                          color: scheme.onSurface,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (widget.showStatus) ...[
                    const SizedBox(width: OcSpace.xs),
                    StatusPill(
                      label: task.status.label,
                      tone: tone,
                      dense: true,
                    ),
                  ],
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    duration: OcDuration.fast,
                    curve: OcDuration.curve,
                    turns: _expanded ? 0.5 : 0,
                    child: OcIcon(
                      OcIcons.chevronDown,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (task.status == TaskStatus.running)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OcSpace.xs,
              0,
              OcSpace.xs,
              OcSpace.xs,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(OcRadius.pill),
              child: LinearProgressIndicator(value: task.progress, minHeight: 4),
            ),
          ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OcSpace.xs,
              0,
              OcSpace.xs,
              OcSpace.sm,
            ),
            child: Container(
              padding: const EdgeInsets.all(OcSpace.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(OcRadius.iconTile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (task.inputMetadata['path'] case final path?
                      when path.isNotEmpty)
                    DetailRow(label: '输入', value: path, mono: true),
                  if (task.outputMetadata['path'] case final path?
                      when path.isNotEmpty)
                    DetailRow(label: '输出', value: path, mono: true),
                  if (task.status == TaskStatus.succeeded)
                    DetailRow(
                      label: '耗时',
                      value: formatDuration(
                        task.updatedAt.difference(task.attemptStartedAt),
                      ),
                    ),
                  if (task.status == TaskStatus.failed) ...[
                    DetailRow(
                      label: '失败原因',
                      value: toolErrorHint(task.error?.code),
                    ),
                    ErrorDetails(
                      code: task.error?.code ?? 'unknown',
                      rawMessage: task.error?.message,
                    ),
                  ],
                  DetailRow(label: '任务 ID', value: task.taskId, mono: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}