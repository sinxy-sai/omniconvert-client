import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 统一的内容卡片：16 圆角、1px 描边、brief 指定的轻投影。
/// 可点击时提供 hover 抬升（桌面端可信赖感的关键细节）。
class OcCard extends StatefulWidget {
  const OcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OcSpace.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = OcRadius.card,
    this.showShadow = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool showShadow;
  final String? semanticLabel;

  @override
  State<OcCard> createState() => _OcCardState();
}

class _OcCardState extends State<OcCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final interactive = widget.onTap != null;
    final radius = BorderRadius.circular(widget.radius);
    final borderColor = _hovered && interactive
        ? scheme.primary.withValues(alpha: 0.5)
        : widget.borderColor ?? scheme.outlineVariant;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: OcDuration.fast,
        curve: OcDuration.curve,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: (widget.showShadow || (_hovered && interactive))
              ? semantics.cardShadow
              : const <BoxShadow>[],
        ),
        child: Material(
          color: widget.color ?? scheme.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: scheme.primary.withValues(alpha: 0.035),
            splashColor: scheme.primary.withValues(alpha: 0.06),
            highlightColor: scheme.primary.withValues(alpha: 0.04),
            child: Semantics(
              button: interactive,
              label: widget.semanticLabel,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// 徽标：pill 形状 + 语义色调，用于状态、处理方式、标签。
enum OcTone { neutral, brand, accent, success, warning, danger, info }

class OcPill extends StatelessWidget {
  const OcPill({
    super.key,
    required this.label,
    this.tone = OcTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final OcTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final (background, foreground) = switch (tone) {
      OcTone.neutral => (scheme.surfaceContainer, scheme.onSurfaceVariant),
      OcTone.brand => (semantics.brandContainer, semantics.onBrandContainer),
      OcTone.accent => (semantics.accentContainer, semantics.onAccentContainer),
      OcTone.success => (semantics.successContainer, semantics.onSuccessContainer),
      OcTone.warning => (semantics.warningContainer, semantics.onWarningContainer),
      OcTone.danger => (semantics.dangerContainer, semantics.onDangerContainer),
      OcTone.info => (semantics.infoContainer, semantics.onInfoContainer),
    };
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(OcRadius.pill),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

/// 图标底板：品牌渐变或语义浅底，用于快捷入口 / 工具卡 / 空态。
class OcIconTile extends StatelessWidget {
  const OcIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.tone = OcTone.brand,
    this.gradient = false,
    this.iconSize,
  });

  final IconData icon;
  final double size;
  final OcTone tone;
  final bool gradient;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final (background, foreground) = switch (tone) {
      OcTone.neutral => (scheme.surfaceContainer, scheme.onSurfaceVariant),
      OcTone.brand => (semantics.brandContainer, semantics.onBrandContainer),
      OcTone.accent => (semantics.accentContainer, semantics.onAccentContainer),
      OcTone.success => (semantics.successContainer, semantics.onSuccessContainer),
      OcTone.warning => (semantics.warningContainer, semantics.onWarningContainer),
      OcTone.danger => (semantics.dangerContainer, semantics.onDangerContainer),
      OcTone.info => (semantics.infoContainer, semantics.onInfoContainer),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ? OcColor.gradientBrand : null,
        color: gradient ? null : background,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: gradient ? null : Border.all(color: foreground.withValues(alpha: 0.1)),
      ),
      child: Icon(
        icon,
        size: iconSize ?? size * 0.48,
        color: gradient ? Colors.white : foreground,
      ),
    );
  }
}

/// 区块标题（工具页 / 任务页 / 首页通用）。
class OcSectionHeader extends StatelessWidget {
  const OcSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: OcSpace.sm),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OcSpace.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 页面头部：eyebrow 标签 + 大标题 + 说明 + 右侧操作区。
class OcPageHeader extends StatelessWidget {
  const OcPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.trailing,
    this.trailingWide,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? trailing;
  final Widget? trailingWide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= OcBreakpoints.tablet;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                OcPill(label: eyebrow!, tone: OcTone.brand, dense: true),
                const SizedBox(height: OcSpace.sm),
              ],
              Text(title, style: textTheme.headlineLarge),
              if (description != null) ...[
                const SizedBox(height: OcSpace.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(description!, style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null && !wide) ...[
          const SizedBox(width: OcSpace.sm),
          trailing!,
        ],
        if (trailingWide != null && wide) ...[
          const SizedBox(width: OcSpace.md),
          trailingWide!,
        ],
      ],
    );
  }
}

/// 空状态：图标 + 标题 + 说明 + 主操作。
class OcEmptyState extends StatelessWidget {
  const OcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.tone = OcTone.brand,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final OcTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OcSpace.lg,
        vertical: OcSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OcIconTile(icon: icon, size: 56, tone: tone),
          const SizedBox(height: OcSpace.md),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: OcSpace.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              description,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: OcSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 提示条：信息 / 成功 / 警告 / 错误，正文可读、可放操作按钮。
class OcNotice extends StatelessWidget {
  const OcNotice({
    super.key,
    required this.message,
    this.title,
    this.tone = OcTone.info,
    this.icon,
    this.action,
    this.details,
  });

  final String message;
  final String? title;
  final OcTone tone;
  final IconData? icon;
  final Widget? action;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantics = OcSemantics.of(context);
    final (background, foreground, defaultIcon) = switch (tone) {
      OcTone.neutral => (
        Theme.of(context).colorScheme.surfaceContainer,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.info_outline_rounded,
      ),
      OcTone.brand => (
        semantics.brandContainer,
        semantics.onBrandContainer,
        Icons.auto_awesome_outlined,
      ),
      OcTone.accent => (
        semantics.accentContainer,
        semantics.onAccentContainer,
        Icons.bolt_outlined,
      ),
      OcTone.success => (
        semantics.successContainer,
        semantics.onSuccessContainer,
        Icons.check_circle_outline_rounded,
      ),
      OcTone.warning => (
        semantics.warningContainer,
        semantics.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      OcTone.danger => (
        semantics.dangerContainer,
        semantics.onDangerContainer,
        Icons.error_outline_rounded,
      ),
      OcTone.info => (
        semantics.infoContainer,
        semantics.onInfoContainer,
        Icons.info_outline_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? defaultIcon, size: 20, color: foreground),
              const SizedBox(width: OcSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: textTheme.titleSmall?.copyWith(color: foreground),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: OcSpace.sm),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: action!,
              ),
            ),
          ],
          if (details != null) ...[
            const SizedBox(height: OcSpace.xs),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: details!,
            ),
          ],
        ],
      ),
    );
  }
}

/// 等宽文本：文件路径、工具 ID、格式名。
class OcMonoText extends StatelessWidget {
  const OcMonoText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 12,
    this.maxLines,
    this.selectable = false,
  });

  final String text;
  final Color? color;
  final double fontSize;
  final int? maxLines;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamilyFallback: ocMonoFallback,
      fontSize: fontSize,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    );
    if (selectable) {
      return SelectableText(text, style: style, maxLines: maxLines);
    }
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// 代码块：用于 LaTeX、路径等需要等宽展示的内容。
class OcCodeBlock extends StatelessWidget {
  const OcCodeBlock({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OcSpace.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final semantics = OcSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: semantics.monoSurface,
        borderRadius: OcRadius.cardBorder,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: semantics.onMonoSurface,
          fontFamilyFallback: ocMonoFallback,
          fontSize: 13,
          height: 1.6,
        ),
        child: child,
      ),
    );
  }
}