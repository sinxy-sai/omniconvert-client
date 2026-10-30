import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'tone.dart';

/// 页面骨架：滚动 + 最大宽度居中 + 响应式留白。
///
/// 宽屏不会把内容硬拉到全宽（那会让中文行长失控），
/// 但也留出足够宽度给工具页的双栏布局。
class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.children,
    this.maxWidth = 1180,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < OcBreakpoints.tablet
            ? OcSpace.md
            : width < OcBreakpoints.rail
            ? OcSpace.lg
            : OcSpace.xl;
        final top = width < OcBreakpoints.rail ? OcSpace.lg : OcSpace.xl;
        final bottom = OcSpace.xl2 + MediaQuery.paddingOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 页面标题区：eyebrow 小标 + 主标题 + 说明 + 右侧操作。
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: (compact
                        ? textTheme.headlineSmall
                        : textTheme.headlineLarge)
                    ?.copyWith(letterSpacing: -0.5),
              ),
              if (description != null) ...[
                const SizedBox(height: OcSpace.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: OcSpace.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// 轻量提示（SnackBar）：保存成功、复制成功这类即时反馈。
void showAppToast(
  BuildContext context,
  String message, {
  OcTone tone = OcTone.neutral,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final icon = switch (tone) {
    OcTone.success => OcIcons.check,
    OcTone.danger => OcIcons.alert,
    OcTone.warning => OcIcons.alert,
    _ => OcIcons.info,
  };
  final iconColor = switch (tone) {
    OcTone.success => const Color(0xFF6EE7B7),
    OcTone.danger => const Color(0xFFFCA5A5),
    OcTone.warning => const Color(0xFFFCD34D),
    _ => const Color(0xFFA5B4FC),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OcIcon(icon, size: 18, color: iconColor),
            const SizedBox(width: OcSpace.xs),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// 区块之间的统一间距。
Widget vgap([double size = OcSpace.lg]) => SizedBox(height: size);

/// 卡片内的「第一步 / 第二步」小标题：序号 + 标题 + 右侧说明。
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.index,
    required this.title,
    this.trailing,
    this.description,
  });

  final int index;
  final String title;
  final Widget? trailing;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$index',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: OcSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(description!, style: textTheme.bodySmall),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: OcSpace.xs),
          trailing!,
        ],
      ],
    );
  }
}