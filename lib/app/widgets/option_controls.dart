import 'package:flutter/material.dart';

import '../../core/tools/tool_registry.g.dart';
import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'surface_card.dart';

/// 枚举型参数的取值文案（未知值原样显示，绝不隐藏）。
String optionValueLabel(String optionId, String value) => switch (
  '$optionId:$value'
) {
  'preset:high' => '高画质',
  'preset:balanced' => '均衡',
  'preset:small' => '最小体积',
  'layout:fit' => '整页铺满',
  'layout:a4' => 'A4 留白',
  _ => value,
};

String optionValueHint(String optionId, String value) => switch (
  '$optionId:$value'
) {
  'preset:high' => '优先画质，体积降得少',
  'preset:balanced' => '画质和体积的平衡点',
  'preset:small' => '优先体积，画质让步',
  'layout:fit' => '页面等于图片原始尺寸，不裁切、不留白',
  'layout:a4' => 'A4 页面内等比缩放居中，四周留白',
  _ => '',
};

/// 整数型参数：滑块 + 当前值。范围直接读 registry 的 min / max。
class OptionSlider extends StatelessWidget {
  const OptionSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.suffix = '%',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? hint;
  final bool enabled;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final span = (max - min).abs();
    final divisions = span <= 0 ? null : (span > 50 ? 19 : span);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: textTheme.titleSmall),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(OcRadius.pill),
              ),
              child: Text(
                '$value$suffix',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontFamilyFallback: ocMonoFallback,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.primary,
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: '$value$suffix',
            onChanged: enabled ? (next) => onChanged(next.round()) : null,
          ),
        ),
        if (hint != null)
          Text(hint!, style: textTheme.bodySmall),
      ],
    );
  }
}

/// 枚举型参数：分段控件（桌面 / 移动都可用，键盘可 Tab 到达）。
class SegmentedOptions extends StatelessWidget {
  const SegmentedOptions({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.optionId = '',
  });

  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool enabled;
  final String optionId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.titleSmall),
        const SizedBox(height: OcSpace.xs),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: semantics.isDark
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(OcRadius.button),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              for (final value in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: value == selected,
                    label: optionValueLabel(optionId, value),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: enabled ? () => onChanged(value) : null,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: OcDuration.fast,
                        curve: OcDuration.curve,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: value == selected
                              ? scheme.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            OcRadius.chip,
                          ),
                          border: Border.all(
                            color: value == selected
                                ? scheme.outlineVariant
                                : Colors.transparent,
                          ),
                          boxShadow: value == selected && !semantics.isDark
                              ? const [
                                  BoxShadow(
                                    color: Color(0x0F0B1220),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          optionValueLabel(optionId, value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: value == selected
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: value == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hint != null && hint!.isNotEmpty) ...[
          const SizedBox(height: OcSpace.xs),
          Text(hint!, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// 布尔型参数：开关。
class OptionSwitch extends StatelessWidget {
  const OptionSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleSmall),
              if (hint != null)
                Text(hint!, style: textTheme.bodySmall),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

/// 按 registry 的 `options` 动态渲染参数区。
///
/// 已知类型 → 滑块 / 分段 / 开关；未知类型 → 只显示当前值并说明不支持，
/// 不会把原始 option id 直接丢给用户看。
class ToolOptionsPanel extends StatelessWidget {
  const ToolOptionsPanel({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  final List<ToolOptionDefinition> options;
  final Map<String, String> values;
  final void Function(String optionId, String value) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Row(
        children: [
          OcIcon(
            OcIcons.sparkle,
            size: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '这个工具不需要额外参数，选好文件即可开始。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(height: OcSpace.md),
          _buildOption(context, options[index], textTheme),
        ],
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    ToolOptionDefinition option,
    TextTheme textTheme,
  ) {
    final current = values[option.id] ?? option.defaultValue ?? '';
    final label = option.label['zh'] ?? option.id;
    switch (option.type) {
      case 'integer':
        final min = option.min ?? 0;
        final max = option.max ?? 100;
        final parsed =
            int.tryParse(current) ??
            int.tryParse(option.defaultValue ?? '') ??
            min;
        return OptionSlider(
          label: label,
          value: parsed.clamp(min, max),
          min: min,
          max: max,
          enabled: enabled,
          onChanged: (value) => onChanged(option.id, '$value'),
          hint: switch (option.id) {
            'quality' => '数值越高画质越好、文件越大；日常分享 80 左右就够。',
            _ => null,
          },
        );
      case 'enum':
        return SegmentedOptions(
          label: label,
          optionId: option.id,
          values: option.values,
          selected: current,
          enabled: enabled,
          onChanged: (value) => onChanged(option.id, value),
          hint: option.values.isEmpty
              ? null
              : optionValueHint(option.id, current),
        );
      case 'boolean':
        return OptionSwitch(
          label: label,
          value: current == 'true',
          enabled: enabled,
          onChanged: (value) => onChanged(option.id, value ? 'true' : 'false'),
        );
      default:
        return Row(
          children: [
            Expanded(child: Text(label, style: textTheme.titleSmall)),
            MonoText(current.isEmpty ? '默认' : current),
          ],
        );
    }
  }
}