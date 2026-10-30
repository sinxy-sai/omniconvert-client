import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 语义色调：徽标、图标底板、提示条共用一套，避免各处随手取色。
enum OcTone { neutral, brand, accent, success, warning, danger, info }

@immutable
class OcToneColors {
  const OcToneColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.solid,
  });

  /// 浅底（徽标 / 提示条背景）。
  final Color background;

  /// 该底色上的可读前景色（对比度 ≥ 4.5:1）。
  final Color foreground;

  /// 描边（比背景略深，不抢眼）。
  final Color border;

  /// 饱和色（图标、进度条、左侧状态条）。
  final Color solid;
}

extension OcToneX on OcTone {
  OcToneColors resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    return switch (this) {
      OcTone.neutral => OcToneColors(
        background: scheme.surfaceContainer,
        foreground: scheme.onSurfaceVariant,
        border: scheme.outlineVariant,
        solid: scheme.onSurfaceVariant,
      ),
      OcTone.brand => OcToneColors(
        background: semantics.brandContainer,
        foreground: semantics.onBrandContainer,
        border: semantics.onBrandContainer.withValues(alpha: 0.16),
        solid: scheme.primary,
      ),
      OcTone.accent => OcToneColors(
        background: semantics.accentContainer,
        foreground: semantics.onAccentContainer,
        border: semantics.onAccentContainer.withValues(alpha: 0.16),
        solid: scheme.secondary,
      ),
      OcTone.success => OcToneColors(
        background: semantics.successContainer,
        foreground: semantics.onSuccessContainer,
        border: semantics.onSuccessContainer.withValues(alpha: 0.16),
        solid: semantics.success,
      ),
      OcTone.warning => OcToneColors(
        background: semantics.warningContainer,
        foreground: semantics.onWarningContainer,
        border: semantics.onWarningContainer.withValues(alpha: 0.18),
        solid: semantics.warning,
      ),
      OcTone.danger => OcToneColors(
        background: semantics.dangerContainer,
        foreground: semantics.onDangerContainer,
        border: semantics.onDangerContainer.withValues(alpha: 0.16),
        solid: semantics.danger,
      ),
      OcTone.info => OcToneColors(
        background: semantics.infoContainer,
        foreground: semantics.onInfoContainer,
        border: semantics.onInfoContainer.withValues(alpha: 0.16),
        solid: scheme.primary,
      ),
    };
  }
}