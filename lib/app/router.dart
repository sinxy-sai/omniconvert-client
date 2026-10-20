import 'package:flutter/material.dart';

import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../features/tools/presentation/tools_page.dart';

enum AppDestination {
  home('/', '首页', Icons.home_outlined, Icons.home_rounded),
  tasks('/tasks', '任务', Icons.history_outlined, Icons.history_rounded),
  tools('/tools', '工具', Icons.widgets_outlined, Icons.widgets_rounded),
  settings('/settings', '设置', Icons.settings_outlined, Icons.settings_rounded);

  const AppDestination(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  static AppDestination fromPath(String? path) =>
      AppDestination.values.firstWhere(
        (item) => item.path == path,
        orElse: () => AppDestination.home,
      );

  Widget buildPage() => switch (this) {
    AppDestination.home => const HomePage(),
    AppDestination.tasks => const TasksPage(),
    AppDestination.tools => const ToolsPage(),
    AppDestination.settings => const SettingsPage(),
  };
}
