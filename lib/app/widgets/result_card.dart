import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 结果卡片：完成态的主视觉 + 下载 / 打开所在文件夹 / 再处理一个。
///
/// 文案契约：「处理完成」必须保留（端到端测试用它判断成功）。
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.fileName,
    this.sizeLabel,
    this.detailLines = const <String>[],
    this.onDownload,
    this.onReveal,
    this.onRestart,
    this.downloadLabel = '下载结果',
    this.downloadHint,
  });

  final String fileName;
  final String? sizeLabel;
  final List<String> detailLines;
  final VoidCallback? onDownload;
  final VoidCallback? onReveal;
  final VoidCallback? onRestart;
  final String downloadLabel;
  final String? downloadHint;

  @override
  Widget build(BuildContext context) {
    final semantics = OcSemantics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OcSpace.md),
      decoration: BoxDecoration(
        color: semantics.successContainer,
        borderRadius: OcRadius.cardBorder,
        border: Border.all(
          color: semantics.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: semantics.success,
                  shape: BoxShape.circle,
                ),
                child: OcIcon(
                  OcIcons.check,
                  size: 16,
                  color: semantics.isDark
                      ? OcColor.darkSuccessContainer
                      : Colors.white,
                ),
              ),
              const SizedBox(width: OcSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '处理完成',
                            style: textTheme.titleSmall?.copyWith(
                              color: semantics.onSuccessContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: '已完成',
                          tone: OcTone.success,
                          dense: true,
                          icon: OcIcons.check,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        // Wrap 不是 Flex，放 Flexible 会抛 ParentData 断言：
                        // 长文件名靠 MonoText 自己的 maxLines + ellipsis 收住。
                        MonoText(
                          fileName,
                          fontSize: 13,
                          weight: FontWeight.w600,
                          maxLines: 1,
                          color: semantics.onSuccessContainer,
                        ),
                        if (sizeLabel != null)
                          Text(
                            '· $sizeLabel',
                            style: textTheme.bodySmall?.copyWith(
                              color: semantics.onSuccessContainer,
                            ),
                          ),
                      ],
                    ),
                    if (detailLines.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detailLines.join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: semantics.onSuccessContainer.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OcSpace.sm),
          Wrap(
            spacing: OcSpace.xs,
            runSpacing: OcSpace.xs,
            children: [
              if (onDownload != null)
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: OcIcon(
                    OcIcons.download,
                    size: 17,
                    color: scheme.onPrimary,
                  ),
                  label: Text(downloadLabel),
                ),
              if (onReveal != null)
                OutlinedButton.icon(
                  onPressed: onReveal,
                  icon: OcIcon(OcIcons.folder, size: 16),
                  label: const Text('打开所在文件夹'),
                ),
              if (onRestart != null)
                TextButton.icon(
                  onPressed: onRestart,
                  icon: OcIcon(OcIcons.refresh, size: 16),
                  label: const Text('再处理一个'),
                ),
            ],
          ),
          if (downloadHint != null && onDownload != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                downloadHint!,
                style: textTheme.bodySmall?.copyWith(
                  color: semantics.onSuccessContainer.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}