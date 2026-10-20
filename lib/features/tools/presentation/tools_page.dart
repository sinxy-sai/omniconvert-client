import 'package:flutter/material.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('选择工具', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('工具将分批开放；这里会清楚标明每个平台可用的处理方式。'),
      const SizedBox(height: 24),
      const _ToolTile(
        icon: Icons.functions,
        title: '手写公式转 LaTeX',
        description: '支持官方免费额度或自建识别服务',
      ),
      const _ToolTile(
        icon: Icons.swap_horiz,
        title: '文件转换',
        description: 'PNG/JPEG/PDF，以及桌面端文档适配器',
      ),
      const _ToolTile(
        icon: Icons.compress,
        title: '图片压缩',
        description: '本地调整尺寸与质量',
      ),
    ],
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Chip(label: Text('规划中')),
    ),
  );
}
