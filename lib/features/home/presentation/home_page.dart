import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/oc_brand.dart';
import '../../../app/widgets/oc_page.dart';
import '../../../app/widgets/oc_surface.dart';
import '../../../app/widgets/task_card.dart';
import '../../../core/tasks/task.dart';
import '../../../core/tasks/task_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.taskRepository});

  final TaskRepository taskRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Task>> _recentTasks = widget.taskRepository.listRecent(
    limit: 4,
  );

  void _reload() {
    setState(() {
      _recentTasks = widget.taskRepository.listRecent(limit: 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OcPage(
      children: [
        _HeroPanel(onOpenTools: () => ocNavigate(context, '/tools')),
        ocGap(OcSpace.xl),
        OcSectionHeader(
          title: '快速开始',
          subtitle: '选择一种处理方式，文件默认在本机完成。',
        ),
        _QuickActionGrid(),
        ocGap(OcSpace.xl2),
        OcSectionHeader(
          title: '最近任务',
          subtitle: '记录只保存在这台设备上。',
          trailing: TextButton(
            onPressed: () => ocNavigate(context, '/tasks'),
            child: const Text('查看全部'),
          ),
        ),
        FutureBuilder<List<Task>>(
          future: _recentTasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return OcNotice(
                tone: OcTone.danger,
                title: '任务记录暂时无法读取',
                message: '可以重试一次；已完成的文件不会被删除。',
                action: OutlinedButton(
                  onPressed: _reload,
                  child: const Text('重试'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const _LoadingCard(label: '正在读取任务记录…');
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) {
              return OcCard(
                child: OcEmptyState(
                  icon: Icons.inbox_outlined,
                  title: '还没有任务',
                  description: '选择工具处理第一个文件，处理结果和记录会出现在这里。',
                  action: FilledButton.icon(
                    onPressed: () => ocNavigate(context, '/tools'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('去选择工具'),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0) const SizedBox(height: OcSpace.sm),
                  TaskCard(
                    task: tasks[i],
                    dense: true,
                    showError: false,
                    onTap: () => ocNavigate(context, '/tasks'),
                  ),
                ],
              ],
            );
          },
        ),
        ocGap(OcSpace.xl2),
        const _TrustStrip(),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onOpenTools});

  final VoidCallback onOpenTools;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= OcBreakpoints.tablet;
        final veryWide = constraints.maxWidth >= OcBreakpoints.desktop;
        final title = Text(
          '文件处理，简单一点。',
          style: (veryWide ? textTheme.displayMedium : textTheme.headlineLarge)
              ?.copyWith(
                color: scheme.onSurface,
                height: 1.15,
                letterSpacing: -0.8,
              ),
        );
        final description = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'OmniConvert 是一个本地优先的文件工具箱：格式转换、图片压缩，打开就能用，'
            '不需要登录，文件默认留在你的设备上。',
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
        final actions = Wrap(
          spacing: OcSpace.sm,
          runSpacing: OcSpace.sm,
          children: [
            FilledButton.icon(
              onPressed: onOpenTools,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('开始处理文件'),
            ),
            OutlinedButton.icon(
              onPressed: () => ocNavigate(context, '/tasks'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('查看任务记录'),
            ),
          ],
        );
        final badges = Wrap(
          spacing: OcSpace.xs,
          runSpacing: OcSpace.xs,
          children: const [
            OcPill(
              label: '本机处理',
              tone: OcTone.success,
              dense: true,
              icon: Icons.shield_outlined,
            ),
            OcPill(
              label: '无需登录',
              tone: OcTone.neutral,
              dense: true,
              icon: Icons.person_outline_rounded,
            ),
            OcPill(
              label: '跨平台',
              tone: OcTone.accent,
              dense: true,
              icon: Icons.devices_outlined,
            ),
          ],
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OcBrandLockup(markSize: 34, showTagline: true),
            const SizedBox(height: OcSpace.lg),
            title,
            const SizedBox(height: OcSpace.sm),
            description,
            const SizedBox(height: OcSpace.lg),
            actions,
            const SizedBox(height: OcSpace.md),
            badges,
          ],
        );

        return Container(
          padding: EdgeInsets.all(wide ? OcSpace.xl : OcSpace.lg),
          decoration: BoxDecoration(
            gradient: semantics.brandSoftGradient,
            borderRadius: OcRadius.panelBorder,
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: semantics.cardShadow,
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: OcSpace.xl),
                    Expanded(child: _HeroPreview()),
                  ],
                )
              : copy,
        );
      },
    );
  }
}

/// 首页右侧的产品示意（纯 Flutter 绘制，不依赖截图/图片资产）。
class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    Widget fileChip({required IconData icon, required String title, required String subtitle}) =>
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OcSpace.sm,
            vertical: OcSpace.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(OcRadius.iconTile),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OcIconTile(icon: icon, size: 32, tone: OcTone.brand),
              const SizedBox(width: OcSpace.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: OcRadius.panelBorder,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: semantics.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('处理示例', style: textTheme.titleSmall),
              ),
              const OcPill(
                label: '在浏览器内完成',
                tone: OcTone.success,
                dense: true,
                icon: Icons.memory_rounded,
              ),
            ],
          ),
          const SizedBox(height: OcSpace.md),
          fileChip(
            icon: Icons.image_outlined,
            title: 'photo.png',
            subtitle: '1.8 MB · 图片',
          ),
          const SizedBox(height: OcSpace.xs),
          Row(
            children: [
              const SizedBox(width: OcSpace.md),
              Icon(
                Icons.south_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text('转换', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: OcSpace.xs),
          fileChip(
            icon: Icons.picture_as_pdf_outlined,
            title: 'photo.jpg',
            subtitle: '420 KB · JPEG',
          ),
          const SizedBox(height: OcSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 6,
              backgroundColor: scheme.outlineVariant,
            ),
          ),
          const SizedBox(height: OcSpace.xs),
          Text(
            '本机处理 · 不上传 · 约 1 秒',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= OcBreakpoints.tablet;
        final items = [
          _QuickAction(
            icon: Icons.swap_horiz_rounded,
            title: '文件转换',
            description: 'PNG ↔ JPEG · 图片 / 文档 → PDF',
            onTap: () => ocNavigate(context, '/tools'),
          ),
          _QuickAction(
            icon: Icons.compress_rounded,
            title: '图片压缩',
            description: '减小体积，画质可控',
            onTap: () => ocNavigate(context, '/tools'),
          ),
          _QuickAction(
            icon: Icons.functions_rounded,
            title: '公式识别',
            description: '手写公式转 LaTeX',
            badge: '暂未开放',
            onTap: () => ocNavigate(context, '/formula'),
          ),
        ];
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: OcSpace.sm),
                items[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: OcSpace.md),
                Expanded(child: items[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OcIconTile(icon: icon, size: 42, gradient: true),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: OcSpace.md),
          Row(
            children: [
              Flexible(child: Text(title, style: textTheme.titleMedium)),
              if (badge != null) ...[
                const SizedBox(width: OcSpace.xs),
                OcPill(label: badge!, tone: OcTone.warning, dense: true),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _TrustItem(
        icon: Icons.shield_outlined,
        title: '本机处理',
        description: '除标注「服务器转换」的工具外，文件不会上传。',
      ),
      _TrustItem(
        icon: Icons.person_outline_rounded,
        title: '无需登录',
        description: '访客模式即可使用全部本地工具。',
      ),
      _TrustItem(
        icon: Icons.code_rounded,
        title: '开源透明',
        description: '客户端开源，可自行构建与审计。',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < OcBreakpoints.tablet) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: OcSpace.sm),
                items[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: OcSpace.md),
              Expanded(child: items[i]),
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

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OcIconTile(icon: icon, size: 36, tone: OcTone.neutral),
        const SizedBox(width: OcSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(description, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OcCard(
      padding: const EdgeInsets.all(OcSpace.xl),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OcSpace.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}