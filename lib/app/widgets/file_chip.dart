import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 已选文件卡片：文件名（等宽）、大小、格式徽标、移除。
class FileChip extends StatelessWidget {
  const FileChip({
    super.key,
    required this.fileName,
    this.sizeLabel,
    this.format,
    this.onRemove,
    this.flowLabel,
    this.busy = false,
  });

  final String fileName;
  final String? sizeLabel;
  final String? format;

  /// 例如「PNG → JPG」，让用户看到当前工具会把文件变成什么。
  final String? flowLabel;
  final VoidCallback? onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final meta = [?sizeLabel, ?flowLabel].join(' · ');

    return Container(
      padding: const EdgeInsets.all(OcSpace.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconTile(OcIcons.file, size: 38, tone: OcTone.brand),
          const SizedBox(width: OcSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: MonoText(
                        fileName,
                        fontSize: 13.5,
                        weight: FontWeight.w600,
                        maxLines: 1,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (format != null) ...[
                      const SizedBox(width: 6),
                      FormatBadge(format!),
                    ],
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: busy ? null : onRemove,
              tooltip: '移除文件',
              icon: OcIcon(
                OcIcons.close,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}