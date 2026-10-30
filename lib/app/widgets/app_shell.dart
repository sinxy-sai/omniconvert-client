import 'package:flutter/material.dart';

import '../icons/oc_icons.dart';
import '../navigation.dart';
import '../theme/tokens.dart';
import 'oc_brand.dart';
import 'surface_card.dart';
import 'tone.dart';

/// 应用外壳：≥840dp 用深墨色 NavigationRail，窄屏用底部 NavigationBar。
///
/// 侧栏在浅色 / 暗色下都保持同一块「深墨工作台」质感，
/// 让内容区成为唯一的浅色焦点（这是产品感的主要来源之一）。
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.current,
    required this.onSelect,
    required this.child,
  });

  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= OcBreakpoints.rail;
        if (wide) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Rail(current: current, onSelect: onSelect),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey<String>(current.path),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            titleSpacing: OcSpace.md,
            title: const OcBrandLockup(markSize: 26, dense: true),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: OcSpace.md),
                child: Center(child: _LocalOnlyPill()),
              ),
            ],
          ),
          body: KeyedSubtree(
            key: ValueKey<String>(current.path),
            child: child,
          ),
          bottomNavigationBar: _BottomBar(
            current: current,
            onSelect: onSelect,
          ),
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.current, required this.onSelect});

  final AppSection current;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final semantics = OcSemantics.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: semantics.navSurface,
        border: Border(right: BorderSide(color: semantics.navBorder)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                OcSpace.lg,
                OcSpace.lg,
                OcSpace.lg,
                OcSpace.lg,
              ),
              child: OcBrandLockup(markSize: 36, invert: true, showTagline: true),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: OcSpace.lg,
                bottom: OcSpace.xs,
              ),
              child: Text(
                '工作区',
                style: textTheme.labelSmall?.copyWith(
                  color: semantics.navInkSoft,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 导航项放在可滚动区域里：窗口被压到很矮时滚动而不是溢出，
            // 底部「本地优先」仍然贴底（Expanded 吃掉多余高度）。
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in AppSection.values)
                      _RailItem(
                        section: section,
                        selected: section == current,
                        onTap: () => onSelect(section),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OcSpace.md,
                OcSpace.md,
                OcSpace.md,
                OcSpace.lg,
              ),
              child: _RailFooter(semantics: semantics),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final semantics = OcSemantics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selected;
    final background = selected
        ? semantics.navActiveSurface
        : _hovered
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.transparent;
    final foreground = selected ? semantics.navActiveInk : semantics.navInkSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OcSpace.sm,
        vertical: 2,
      ),
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.section.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: OcDuration.fast,
            curve: OcDuration.curve,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(OcRadius.button),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(OcRadius.button),
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              hoverColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OcSpace.sm,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: OcDuration.fast,
                      curve: OcDuration.curve,
                      width: 3,
                      height: selected ? 18 : 0,
                      decoration: BoxDecoration(
                        color: semantics.navActiveAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: selected ? 9 : 12),
                    OcIcon(
                      widget.section.icon,
                      key: Key('navigation-${widget.section.name}'),
                      size: 19,
                      color: selected
                          ? semantics.navActiveInk
                          : semantics.navInkSoft,
                    ),
                    const SizedBox(width: OcSpace.sm),
                    Expanded(
                      child: Text(
                        widget.section.label,
                        style: textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailFooter extends StatelessWidget {
  const _RailFooter({required this.semantics});

  final OcSemantics semantics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(OcSpace.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OcRadius.iconTile),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: OcIcon(
              OcIcons.lock,
              size: 14,
              color: semantics.navInkSoft,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本地优先',
                  style: textTheme.labelMedium?.copyWith(
                    color: semantics.navInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '文件默认在本机处理，不上传。',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantics.navInkSoft,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current, required this.onSelect});

  final AppSection current;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (index) =>
              onSelect(AppSection.values[index]),
          destinations: [
            for (final section in AppSection.values)
              NavigationDestination(
                icon: OcIcon(
                  section.icon,
                  key: Key('navigation-${section.name}'),
                  size: 21,
                  color: scheme.onSurfaceVariant,
                ),
                selectedIcon: OcIcon(
                  section.icon,
                  key: Key('navigation-${section.name}'),
                  size: 21,
                  color: scheme.primary,
                ),
                label: section.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _LocalOnlyPill extends StatelessWidget {
  const _LocalOnlyPill();

  @override
  Widget build(BuildContext context) {
    return const StatusPill(
      label: '本机处理',
      tone: OcTone.success,
      icon: OcIcons.shield,
      dense: true,
    );
  }
}