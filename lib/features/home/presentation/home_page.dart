import 'package:flutter/material.dart';

import '../../../app/icons/oc_icons.dart';
import '../../../app/navigation.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/tools/selected_tool.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../app/widgets/page_layout.dart';
import '../../../app/widgets/skeleton.dart';
import '../../../app/widgets/surface_card.dart';
import '../../../app/widgets/task_row.dart';
import '../../../app/widgets/tone.dart';
import '../../../app/widgets/tool_tile.dart';
import '../../../core/tasks/task.dart';
import '../../../core/tasks/task_repository.dart';
import '../../../core/tools/tool_registry.g.dart';

/// 首页：一句话价值 + 主 CTA + 工具入口 + 最近任务。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.taskRepository});

  final TaskRepository taskRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Task>> _recent = widget.taskRepository.listRecent(limit: 4);

  void _reload() => setState(() {
    _recent = widget.taskRepository.listRecent(limit: 4);
  });

  void _openTools([String? toolId]) {
    if (toolId != null) ToolSelection.request(toolId);
    Navigator.of(context).pushReplacementNamed(AppSection.tools.path);
  }

  void _openTasks() =>
      Navigator.of(context).pushReplacementNamed(AppSection.tasks.path);

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      children: [
        _HeroPanel(
          onPrimary: () => _openTools(),
          onSecondary: _openTasks,
        ),
        vgap(OcSpace.xl),
        SectionHeader(
          title: '工具速用',
          description: '${kToolDefinitions.length} 个工具，图片处理默认在本机完成',
          trailing: TextButton(
            onPressed: () => _openTools(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('全部工具'),
                SizedBox(width: 4),
                OcIcon(OcIcons.arrowRight, size: 15),
              ],
            ),
          ),
        ),
        vgap(OcSpace.sm),
        _CapabilityGrid(onSelect: _openTools),
        vgap(OcSpace.xl),
        SectionHeader(
          title: '最近任务',
          description: '记录只保存在这台设备上',
          trailing: TextButton(
            onPressed: _openTasks,
            child: const Text('查看全部'),
          ),
        ),
        vgap(OcSpace.xs),
        FutureBuilder<List<Task>>(
          future: _recent,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return InlineAlertHost(
                message: '任务记录暂时无法读取，可以重试一次；已完成的文件不会被删除。',
                onRetry: _reload,
              );
            }
            if (!snapshot.hasData) {
              return const SurfaceCard(
                padding: EdgeInsets.all(OcSpace.md),
                child: SkeletonLines(lines: 3),
              );
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) {
              return EmptyStatePanel(
                icon: OcIcons.tasks,
                title: '还没有任务',
                description: '选择工具处理第一个文件，结果和记录会出现在这里。',
                action: FilledButton.icon(
                  onPressed: () => _openTools(),
                  icon: const OcIcon(OcIcons.arrowRight, size: 16),
                  label: const Text('去选择工具'),
                ),
              );
            }
            return SurfaceCard(
              padding: const EdgeInsets.symmetric(
                horizontal: OcSpace.xs,
                vertical: OcSpace.xxs,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < tasks.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    TaskRow(task: tasks[index], showStatus: true),
                  ],
                ],
              ),
            );
          },
        ),
        vgap(OcSpace.xl),
        const _TrustStrip(),
      ],
    );
  }
}

class InlineAlertHost extends StatelessWidget {
  const InlineAlertHost({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(OcSpace.md),
      child: Row(
        children: [
          OcIcon(
            OcIcons.alert,
            size: 18,
            color: OcSemantics.of(context).warning,
          ),
          const SizedBox(width: OcSpace.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 首屏主视觉：左侧文案 + 右侧产品预览，背景是品牌光斑 + 点阵。
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onPrimary, required this.onSecondary});

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: OcSpace.xs,
              runSpacing: OcSpace.xs,
              children: const [
                StatusPill(
                  label: '本机处理',
                  tone: OcTone.success,
                  icon: OcIcons.shield,
                  dense: true,
                ),
                StatusPill(
                  label: '无需登录',
                  tone: OcTone.neutral,
                  dense: true,
                ),
                StatusPill(
                  label: '开源',
                  tone: OcTone.accent,
                  dense: true,
                ),
              ],
            ),
            SizedBox(height: OcSpace.md),
            Text(
              '文件处理，简单一点。',
              style: (wide ? textTheme.displayLarge : textTheme.headlineLarge)
                  ?.copyWith(height: 1.18, letterSpacing: -1),
            ),
            const SizedBox(height: OcSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                '转换格式、压缩图片、导出 PDF —— 打开就能用。图片处理全部在本机完成，文件不会离开你的设备。',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.75,
                ),
              ),
            ),
            const SizedBox(height: OcSpace.lg),
            Wrap(
              spacing: OcSpace.xs,
              runSpacing: OcSpace.xs,
              children: [
                FilledButton.icon(
                  onPressed: onPrimary,
                  icon: const OcIcon(OcIcons.arrowRight, size: 16),
                  label: const Text('开始处理文件'),
                ),
                OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: const OcIcon(OcIcons.tasks, size: 16),
                  label: const Text('查看任务记录'),
                ),
              ],
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: semantics.heroSurface,
            borderRadius: OcRadius.panelBorder,
            border: Border.all(color: semantics.heroBorder),
            boxShadow: semantics.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: OcRadius.panelBorder,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: OcAuroraPainter(
                      primary: scheme.primary,
                      secondary: scheme.secondary,
                      intensity: semantics.isDark ? 0.55 : 1,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: OcDotPatternPainter(color: semantics.gridDot),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(wide ? OcSpace.xl : OcSpace.lg),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: copy),
                            const SizedBox(width: OcSpace.lg),
                            const Expanded(flex: 5, child: _ProductPreview()),
                          ],
                        )
                      : copy,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 纯 Flutter 绘制的产品预览：不用截图，也不会随版本过期。
class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);

    Widget fileRow({
      required OcIconData icon,
      required String name,
      required String meta,
      required String format,
      bool highlight = false,
    }) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OcSpace.sm,
        vertical: OcSpace.xs + 2,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primary.withValues(alpha: 0.06)
            : scheme.surface,
        borderRadius: BorderRadius.circular(OcRadius.iconTile),
        border: Border.all(
          color: highlight
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          IconTile(icon, size: 30, tone: OcTone.brand),
          const SizedBox(width: OcSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: MonoText(
                        name,
                        fontSize: 12.5,
                        weight: FontWeight.w600,
                        maxLines: 1,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 5),
                    FormatBadge(format),
                  ],
                ),
                Text(meta, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(OcSpace.sm),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: semantics.isDark ? 0.6 : 0.86),
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: semantics.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final color in [
                const Color(0xFFF87171),
                const Color(0xFFFBBF24),
                const Color(0xFF34D399),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '本机处理',
                style: textTheme.labelSmall?.copyWith(
                  color: semantics.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: OcSpace.sm),
          fileRow(
            icon: OcIcons.image,
            name: 'red.png',
            meta: '1.8 MB',
            format: 'png',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: OcSpace.md),
                OcIcon(OcIcons.arrowRight, size: 13, color: scheme.primary),
                const SizedBox(width: 5),
                Text('转换', style: textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          fileRow(
            icon: OcIcons.imageToPdf,
            name: 'red.pdf',
            meta: '420 KB',
            format: 'pdf',
            highlight: true,
          ),
          const SizedBox(height: OcSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(OcRadius.pill),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 5,
              backgroundColor: scheme.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '不上传 · 不需要登录 · 约 1 秒',
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CapabilityGrid extends StatelessWidget {
  const _CapabilityGrid({required this.onSelect});

  final void Function(String toolId) onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 560
            ? 2
            : 1;
        const spacing = OcSpace.sm;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final definition in kToolDefinitions)
              SizedBox(
                width: itemWidth,
                child: ToolTile(
                  definition: definition,
                  selected: false,
                  dense: true,
                  onTap: () => onSelect(definition.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = <(OcIconData, String, String)>[
      (
        OcIcons.shield,
        '本机处理',
        '标注「本机」的工具不上传文件，处理在浏览器 / 本机完成。',
      ),
      (
        OcIcons.lock,
        '用完即删',
        '标注「服务器」的工具会临时上传，转换完成后立即删除。',
      ),
      (
        OcIcons.sparkle,
        '不收集数据',
        '没有埋点与广告 SDK，不需要手机号或邮箱。',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final children = [
          for (final (icon, title, description) in items)
            _TrustItem(icon: icon, title: title, description: description),
        ];
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: OcSpace.sm),
                children[index],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: OcSpace.lg),
              Expanded(child: children[index]),
            ],
          ],
        );
      },
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final OcIconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, size: 32, tone: OcTone.neutral),
        const SizedBox(width: OcSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 1),
              Text(description, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}