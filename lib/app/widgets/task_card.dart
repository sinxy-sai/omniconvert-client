import 'package:flutter/material.dart';

import '../error_text.dart';
import '../format.dart';
import '../tool_catalog.dart';
import '../theme/tokens.dart';
import 'oc_surface.dart';
import '../../core/tasks/task.dart';
import '../../core/tasks/task_status.dart';

OcTone taskStatusTone(TaskStatus status) => switch (status) {
  TaskStatus.queued || TaskStatus.running => OcTone.brand,
  TaskStatus.succeeded => OcTone.success,
  TaskStatus.failed => OcTone.danger,
  TaskStatus.cancelled => OcTone.neutral,
  TaskStatus.interrupted => OcTone.warning,
};

/// 任务卡片：首页用紧凑版，任务页用详情版。
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.dense = false,
    this.showError = true,
    this.showStatus = true,
    this.onTap,
  });

  final Task task;
  final bool dense;
  final bool showError;
  final bool showStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final spec = toolSpecFor(task.toolId);
    final fileName = task.inputMetadata['name'] ?? toolDisplayName(task.toolId);
    final outputPath = task.outputMetadata['path'];
    final tone = taskStatusTone(task.status);
    final iconTone = switch (tone) {
      OcTone.danger => OcTone.danger,
      OcTone.success => OcTone.success,
      OcTone.warning => OcTone.warning,
      OcTone.neutral => OcTone.neutral,
      _ => OcTone.brand,
    };

    return OcCard(
      onTap: onTap,
      padding: EdgeInsets.all(dense ? OcSpace.md : OcSpace.lg),
      semanticLabel: '$fileName，${task.status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OcIconTile(
                icon: spec?.icon ?? toolIcon(task.toolId),
                size: dense ? 38 : 44,
                tone: iconTone,
              ),
              const SizedBox(width: OcSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${toolDisplayName(task.toolId)} · '
                      '${formatRelativeTime(task.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showStatus) ...[
                const SizedBox(width: OcSpace.xs),
                OcPill(
                  label: task.status.label,
                  tone: tone,
                  dense: true,
                ),
              ],
            ],
          ),
          if (!dense && task.status == TaskStatus.running) ...[
            const SizedBox(height: OcSpace.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: task.progress),
            ),
            const SizedBox(height: 6),
            Text(
              '处理中 · ${(task.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: textTheme.bodySmall,
            ),
          ],
          if (!dense && task.status == TaskStatus.succeeded) ...[
            const SizedBox(height: OcSpace.md),
            Wrap(
              spacing: OcSpace.sm,
              runSpacing: OcSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OcPill(
                  label: switch (task.executionMode) {
                    ExecutionMode.local => '本机处理',
                    ExecutionMode.selfHosted => '自建服务',
                    ExecutionMode.officialCloud => '官方服务',
                  },
                  tone: OcTone.success,
                  dense: true,
                  icon: Icons.check_rounded,
                ),
                Text(
                  '耗时 ${formatDuration(task.updatedAt.difference(task.attemptStartedAt))}',
                  style: textTheme.bodySmall,
                ),
                if (task.outputMetadata['bytes'] != null)
                  Text(
                    '输出 ${formatFileSize(int.tryParse(task.outputMetadata['bytes']!) ?? 0)}',
                    style: textTheme.bodySmall,
                  ),
              ],
            ),
            if (outputPath != null && outputPath.isNotEmpty) ...[
              const SizedBox(height: OcSpace.xs),
              OcMonoText('输出：$outputPath', maxLines: 2),
            ],
          ],
          if (!dense && task.status == TaskStatus.failed && showError) ...[
            const SizedBox(height: OcSpace.md),
            OcNotice(
              tone: OcTone.danger,
              title: '处理没有完成',
              message: toolErrorHint(task.error?.code),
            ),
            if (task.error != null) ...[
              const SizedBox(height: OcSpace.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OcSpace.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(OcRadius.chip),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('技术详情', style: textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: OcSpace.sm,
                      runSpacing: 2,
                      children: [
                        OcMonoText('错误码：${task.error!.code}'),
                        OcMonoText(task.error!.message),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (!dense) ...[
            const SizedBox(height: OcSpace.sm),
            Wrap(
              spacing: OcSpace.md,
              runSpacing: 2,
              children: [
                OcMonoText('任务 ID：${_shortId(task.taskId)}'),
                if (task.inputMetadata['path'] case final path?
                    when path.isNotEmpty) OcMonoText('输入：$path', maxLines: 1),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortId(String id) =>
      id.length <= 22 ? id : '${id.substring(0, 10)}…${id.substring(id.length - 6)}';
}