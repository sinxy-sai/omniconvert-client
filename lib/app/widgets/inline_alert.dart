import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 内联提示条：说明发生了什么、下一步怎么做。
///
/// 错误场景下的 `details` 用来折叠展示错误码等技术信息，
/// 主文案永远是可读中文。
class InlineAlert extends StatelessWidget {
  const InlineAlert({
    super.key,
    required this.message,
    this.title,
    this.tone = OcTone.info,
    this.icon,
    this.action,
    this.details,
    this.dense = false,
  });

  final String message;
  final String? title;
  final OcTone tone;
  final OcIconData? icon;
  final Widget? action;
  final Widget? details;
  final bool dense;

  static OcIconData _defaultIcon(OcTone tone) => switch (tone) {
    OcTone.success => OcIcons.check,
    OcTone.warning => OcIcons.alert,
    OcTone.danger => OcIcons.alert,
    OcTone.info => OcIcons.info,
    OcTone.brand => OcIcons.sparkle,
    OcTone.accent => OcIcons.sparkle,
    OcTone.neutral => OcIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = tone.resolve(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? OcSpace.sm : OcSpace.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: OcIcon(
              icon ?? _defaultIcon(tone),
              size: 18,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: OcSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.foreground,
                    height: 1.6,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: OcSpace.xs),
                  DefaultTextStyle.merge(
                    style: TextStyle(color: colors.foreground),
                    child: action!,
                  ),
                ],
                if (details != null) ...[
                  const SizedBox(height: OcSpace.xs),
                  details!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 可折叠的错误技术详情：错误码 + 原始信息，默认收起。
class ErrorDetails extends StatelessWidget {
  const ErrorDetails({
    super.key,
    required this.code,
    this.rawMessage,
    this.foreground,
  });

  final String code;
  final String? rawMessage;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = foreground ?? scheme.onSurfaceVariant;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      // 折叠区内部是 ListTile：它把背景与水波纹画在最近的 Material 上。
      // 这里自带一层透明 Material，既让水波纹可见，也避免
      // 「ListTile background color may be invisible」的断言（本组件经常
      // 被放在带底色的 Container 里，例如任务行详情）。
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: OcSpace.xs),
          dense: true,
          iconColor: color,
          collapsedIconColor: color,
          leading: const SizedBox.shrink(),
          title: Text(
            '技术详情（反馈问题时请附上）',
            style: textTheme.bodySmall?.copyWith(color: color),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoText('错误码：$code', color: color),
                  if (rawMessage != null && rawMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: MonoText(rawMessage!, color: color, maxLines: 4),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}