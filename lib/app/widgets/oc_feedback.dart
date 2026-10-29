import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'oc_surface.dart';

/// 统一提示：悬浮 SnackBar，带语义图标与中文文案。
///
/// 用于「已保存」「已复制」这类即时反馈；需要常驻的错误/结果信息用 OcNotice。
void showOcMessage(
  BuildContext context,
  String message, {
  OcTone tone = OcTone.neutral,
}) {
  // 页面可能被单独挂载（例如设置页的 widget test）而没有 Scaffold，
  // 此时不弹提示，避免 ScaffoldMessenger 断言。
  if (Scaffold.maybeOf(context) == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final icon = switch (tone) {
    OcTone.success => Icons.check_circle_outline_rounded,
    OcTone.danger => Icons.error_outline_rounded,
    OcTone.warning => Icons.warning_amber_rounded,
    _ => Icons.info_outline_rounded,
  };
  final iconColor = switch (tone) {
    OcTone.success => const Color(0xFF6EE7B7),
    OcTone.danger => const Color(0xFFFCA5A5),
    OcTone.warning => const Color(0xFFFCD34D),
    _ => const Color(0xFFA5B4FC),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: OcSpace.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}