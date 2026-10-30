import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 空态：图标 + 标题 + 一句可执行的说明 + 主操作。
///
/// 刻意做得紧凑：空态不该占满整屏，页面还需要露出下一步的去处。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.tone = OcTone.brand,
  });

  final OcIconData icon;
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
          IconTile(icon, size: 48, tone: tone),
          const SizedBox(height: OcSpace.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: OcSpace.xxs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: OcSpace.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 空态外壳：虚线边框、浅底，避免「大白块」切断页面节奏。
class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.tone = OcTone.brand,
  });

  final OcIconData icon;
  final String title;
  final String description;
  final Widget? action;
  final OcTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: EmptyState(
        icon: icon,
        title: title,
        description: description,
        action: action,
        tone: tone,
      ),
    );
  }
}