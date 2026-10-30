import 'package:flutter/material.dart';

import '../../core/tools/tool_registry.g.dart';
import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import '../tools/tool_display.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 工具卡片：名称与摘要来自 registry，右下角标出「本机 / 服务器」。
///
/// 文案契约（端到端测试依赖）：卡片上必须出现 registry 的 `name['zh']` 原文。
class ToolTile extends StatelessWidget {
  const ToolTile({
    super.key,
    required this.definition,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final ToolDefinition definition;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = definition.name['zh'] ?? definition.id;
    final summary = definition.summary['zh'] ?? '';
    final inputs = definition.inputExtensions
        .map(formatBadgeLabel)
        .toSet()
        .toList(growable: false);

    return Semantics(
      button: true,
      selected: selected,
      label: '$name，${definition.isLocal ? '本机处理' : '服务器转换'}',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        selected: selected,
        semanticButton: false,
        padding: EdgeInsets.all(dense ? OcSpace.sm : OcSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  toolIconFor(definition.id),
                  size: dense ? 32 : 38,
                  gradient: selected,
                  tone: OcTone.brand,
                ),
                const Spacer(),
                StatusPill(
                  label: definition.isLocal ? '本机' : '服务器',
                  tone: definition.isLocal ? OcTone.success : OcTone.info,
                  icon: definition.isLocal ? OcIcons.chip : OcIcons.cloud,
                  dense: true,
                ),
              ],
            ),
            SizedBox(height: dense ? OcSpace.xs : OcSpace.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? textTheme.titleSmall : textTheme.titleMedium)
                  ?.copyWith(
                    color: selected ? scheme.onSurface : null,
                    fontSize: dense ? 13.5 : null,
                  ),
            ),
            if (!dense) ...[
              const SizedBox(height: 3),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(height: 1.55),
              ),
            ],
            SizedBox(height: dense ? 6 : OcSpace.sm),
            if (dense)
              // 窄屏横向工具条里的瓦片只有 ~162dp 宽：五个格式徽标必然换行，
              // 两行徽标把卡片顶出固定高度（历史 RenderFlex overflow）。
              // dense 模式改用单行、可省略的格式流说明。
              Text(
                formatFlowLabel(definition),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamilyFallback: ocMonoFallback,
                  letterSpacing: 0.2,
                ),
              )
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final input in inputs) FormatBadge(input),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: OcIcon(
                      OcIcons.arrowRight,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  FormatBadge(
                    definition.keepsFormat
                        ? (inputs.isEmpty ? '原格式' : inputs.first)
                        : definition.outputExtension,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}