import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 统一的页面容器：滚动 + 最大宽度居中 + 响应式留白。
///
/// 所有页面都只通过 `OcPage` 提供内容，避免每页各写一套 padding。
class OcPage extends StatelessWidget {
  const OcPage({
    super.key,
    required this.children,
    this.maxWidth = 1120,
    this.scrollController,
  });

  final List<Widget> children;
  final double maxWidth;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < OcBreakpoints.tablet
            ? OcSpace.md
            : width < OcBreakpoints.rail
            ? OcSpace.lg
            : OcSpace.xl;
        final top = width < OcBreakpoints.rail ? OcSpace.lg : OcSpace.xl2;
        final bottom = OcSpace.xl2 + MediaQuery.paddingOf(context).bottom;
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 页面之间的导航辅助（保留 router 为唯一路由来源）。
void ocNavigate(BuildContext context, String path) {
  Navigator.of(context).pushReplacementNamed(path);
}

/// 常用间距小工具：页面内区块之间统一留白。
Widget ocGap([double size = OcSpace.lg]) => SizedBox(height: size);

/// 用于需要横向滚动的小组件（窄屏卡片行）。
class OcScrollRow extends StatelessWidget {
  const OcScrollRow({
    super.key,
    required this.children,
    this.spacing = OcSpace.sm,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}