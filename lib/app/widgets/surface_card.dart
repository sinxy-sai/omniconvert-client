import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import '../tools/tool_display.dart' show formatBadgeLabel;
import 'tone.dart';

/// 统一的内容卡片：16 圆角、1px 描边、可选顶部品牌渐变细线。
///
/// 可点击时提供 hover 抬升（桌面端的可信赖感来自这种小反馈）。
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OcSpace.lg),
    this.onTap,
    this.background,
    this.borderColor,
    this.radius = OcRadius.card,
    this.elevated = false,
    this.selected = false,
    this.accentLine = false,
    this.semanticLabel,
    this.semanticButton,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final bool selected;
  final bool accentLine;
  final String? semanticLabel;
  final bool? semanticButton;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final interactive = widget.onTap != null;
    final borderRadius = BorderRadius.circular(widget.radius);
    final hovered = _hovered && interactive;

    final borderColor = widget.selected
        ? scheme.primary
        : hovered
        ? scheme.primary.withValues(alpha: 0.45)
        : widget.borderColor ?? scheme.outlineVariant;
    final background =
        widget.background ??
        (widget.selected
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.045),
                scheme.surface,
              )
            : scheme.surface);
    final shadow = (widget.elevated || hovered || widget.selected)
        ? semantics.cardShadow
        : const <BoxShadow>[];

    Widget content = Padding(padding: widget.padding, child: widget.child);

    if (widget.accentLine) {
      content = Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: semantics.brandGradient,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(widget.radius),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: OcDuration.fast,
        curve: OcDuration.curve,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: widget.selected ? 1.6 : 1,
          ),
          boxShadow: shadow,
        ),
        child: Material(
          color: background,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: scheme.primary.withValues(alpha: 0.03),
            splashColor: scheme.primary.withValues(alpha: 0.06),
            highlightColor: scheme.primary.withValues(alpha: 0.04),
            child: (interactive || widget.semanticLabel != null)
                ? Semantics(
                    button: widget.semanticButton ?? interactive,
                    selected: widget.selected,
                    label: widget.semanticLabel,
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}

/// 图标底板：语义浅底或品牌渐变，统一 12~16 圆角。
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 44,
    this.tone = OcTone.brand,
    this.gradient = false,
  });

  final OcIconData icon;
  final double size;
  final OcTone tone;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final colors = gradient
        ? OcToneColors(
            background: Colors.transparent,
            foreground: Colors.white,
            border: Colors.transparent,
            solid: scheme.primary,
          )
        : tone.resolve(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient ? semantics.brandGradient : null,
        color: gradient ? null : colors.background,
        borderRadius: BorderRadius.circular(size * 0.29),
        border: gradient ? null : Border.all(color: colors.border),
      ),
      child: OcIcon(
        icon,
        size: size * 0.5,
        color: colors.foreground,
      ),
    );
  }
}

/// 区块标题：可选 eyebrow 小标 + 标题 + 说明 + 右侧操作。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.description,
    this.eyebrow,
    this.trailing,
    this.icon,
    this.dense = false,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? description;
  final String? eyebrow;
  final Widget? trailing;
  final OcIconData? icon;
  final bool dense;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: OcIcon(
                icon!,
                size: dense ? 16 : 18,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: OcSpace.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: (dense ? textTheme.titleSmall : textTheme.titleLarge)
                      ?.copyWith(letterSpacing: -0.2),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: textTheme.bodySmall,
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
      ),
    );
  }
}

/// 状态徽标：pill 形状 + 语义色，用于状态 / 处理方式 / 标签。
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = OcTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final OcTone tone;
  final OcIconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = tone.resolve(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(OcRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            OcIcon(icon!, size: dense ? 11 : 12, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: (dense ? textTheme.labelSmall : textTheme.labelMedium)
                ?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// 格式徽标：PNG / JPG / PDF 等等宽大写小标签。
class FormatBadge extends StatelessWidget {
  const FormatBadge(this.format, {super.key, this.outlined = false});

  final String format;
  final bool outlined;

  static (Color, Color) _colors(BuildContext context, String format) {
    final isDark = OcSemantics.of(context).isDark;
    final light = switch (format.toUpperCase()) {
      'PNG' => (OcColor.formatPngBg, OcColor.formatPngFg),
      'JPG' || 'JPEG' => (OcColor.formatJpgBg, OcColor.formatJpgFg),
      'PDF' => (OcColor.formatPdfBg, OcColor.formatPdfFg),
      'DOCX' || 'DOC' => (OcColor.formatDocBg, OcColor.formatDocFg),
      'MOBI' || 'EPUB' || 'AZW' || 'AZW3' => (
        OcColor.formatBookBg,
        OcColor.formatBookFg,
      ),
      _ => (
        Theme.of(context).colorScheme.surfaceContainer,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };
    if (!isDark) return light;
    return (
      Color.alphaBlend(light.$2.withValues(alpha: 0.16),
          Theme.of(context).colorScheme.surface),
      Color.alphaBlend(
        light.$2.withValues(alpha: 0.55),
        Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 只走 formatBadgeLabel 这一条出口：JPEG 必须显示成 JPG，
    // 否则同一页里「PNG · JPG · JPEG → 原格式」和徽标会自相矛盾。
    final label = formatBadgeLabel(format);
    if (label.isEmpty) return const SizedBox.shrink();
    final (background, foreground) = _colors(context, label);
    return Semantics(
      label: '$label 格式',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: outlined ? null : background,
          border: Border.all(
            color: outlined ? foreground.withValues(alpha: 0.45) : background,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: foreground,
            fontFamilyFallback: ocMonoFallback,
          ),
        ),
      ),
    );
  }
}

/// 等宽文本：文件名、路径、哈希。
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 12,
    this.maxLines,
    this.selectable = false,
    this.weight,
  });

  final String text;
  final Color? color;
  final double fontSize;
  final int? maxLines;
  final bool selectable;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamilyFallback: ocMonoFallback,
      fontSize: fontSize,
      height: 1.5,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
    if (selectable) return SelectableText(text, style: style, maxLines: maxLines);
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// 一行「标签 + 值」，设置页与任务详情复用。
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: mono
                ? MonoText(
                    value,
                    fontSize: 12.5,
                    color: valueColor ?? scheme.onSurface,
                    selectable: true,
                  )
                : Text(
                    value,
                    style: textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? scheme.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}