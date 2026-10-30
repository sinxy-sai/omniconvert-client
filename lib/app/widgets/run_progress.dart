import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'surface_card.dart';

/// 运行进度：进度条 + 阶段文案 + 百分比；`progress` 为 null 时显示不确定态。
class RunProgress extends StatelessWidget {
  const RunProgress({
    super.key,
    required this.label,
    this.progress,
    this.percentLabel,
    this.tone,
  });

  final String label;
  final double? progress;
  final String? percentLabel;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = progress?.clamp(0.0, 1.0);
    final percent = value == null
        ? null
        : percentLabel ?? '${(value * 100).round()}%';
    return Semantics(
      label: percent == null ? label : '$label，$percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (percent != null)
                MonoText(
                  percent,
                  fontSize: 12.5,
                  color: tone ?? scheme.primary,
                  weight: FontWeight.w600,
                ),
            ],
          ),
          const SizedBox(height: OcSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(OcRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: tone ?? scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}