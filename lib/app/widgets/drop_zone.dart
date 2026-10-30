import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../icons/oc_icons.dart';
import '../theme/tokens.dart';
import 'file_drop.dart';
import 'surface_card.dart';

/// 拖拽区：桌面 / Web 支持把文件拖进窗口，其它情况点击选择。
///
/// 虚线描边 + 悬停高亮 + 拖动时整体换色，是「这是个能放东西的地方」的唯一表达。
class DropZone extends StatefulWidget {
  const DropZone({
    super.key,
    required this.onPick,
    required this.onDropFile,
    required this.acceptedLabel,
    this.maxBytes,
    this.enabled = true,
    this.compact = false,
    this.errorText,
  });

  final VoidCallback onPick;
  final ValueChanged<DroppedFile> onDropFile;

  /// 例如「PNG」或「PNG · JPG」。
  final String acceptedLabel;
  final int? maxBytes;
  final bool enabled;
  final bool compact;
  final String? errorText;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _hovered = false;
  bool _dragging = false;

  bool get _desktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _handleDrop(List<DroppedFile> files) {
    if (files.isEmpty) return;
    // 一次只处理一个文件：多选时取第一个，避免静默丢弃。
    widget.onDropFile(files.first);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = OcSemantics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final active = _dragging;
    final highlighted = active || _hovered;

    final borderColor = widget.errorText != null
        ? semantics.danger
        : highlighted
        ? scheme.primary
        : scheme.outline;
    final background = active
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surface,
          )
        : highlighted
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.04),
            scheme.surface,
          )
        : scheme.surface;

    final content = MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPick : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: OcDuration.fast,
          curve: OcDuration.curve,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: OcSpace.lg,
            vertical: widget.compact ? OcSpace.lg : OcSpace.xl,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: OcRadius.cardBorder,
            border: Border.all(
              color: borderColor.withValues(alpha: widget.errorText != null ? 1 : 0.55),
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: OcDuration.fast,
                curve: OcDuration.curve,
                scale: active ? 1.06 : 1,
                child: IconTile(
                  active ? OcIcons.download : OcIcons.upload,
                  size: widget.compact ? 40 : 48,
                  gradient: true,
                ),
              ),
              SizedBox(height: widget.compact ? OcSpace.xs : OcSpace.sm),
              Text(
                '选择文件',
                style: textTheme.titleSmall?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                _supportLine(),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              if (_desktop && !widget.compact) ...[
                const SizedBox(height: OcSpace.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OcIcon(
                      OcIcons.upload,
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      active ? '松开即可添加' : '也可以把文件直接拖进窗口',
                      style: textTheme.bodySmall?.copyWith(
                        color: active ? scheme.primary : null,
                        fontWeight: active ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.errorText != null) ...[
                const SizedBox(height: OcSpace.xs),
                Text(
                  widget.errorText!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: semantics.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return ocFileDropRegion(
      onDrop: widget.enabled ? _handleDrop : (_) {},
      onDragChanged: (dragging) {
        if (mounted) setState(() => _dragging = dragging);
      },
      child: content,
    );
  }

  String _supportLine() {
    final limit = widget.maxBytes;
    final limitLabel = limit == null ? null : '单个文件不超过 ${formatFileSize(limit)}';
    return ['支持 ${widget.acceptedLabel}', ?limitLabel].join(' · ');
  }
}