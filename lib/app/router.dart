import 'package:flutter/material.dart';

import '../core/tasks/task_repository.dart';
import '../core/tools/tool_execution_service.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../features/tools/presentation/tools_page.dart';
import 'navigation.dart';

/// 应用运行期依赖：由 `OmniConvertApp` 构造一次，路由只负责分发。
class AppDependencies {
  const AppDependencies({
    required this.taskRepository,
    required this.toolService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final TaskRepository taskRepository;
  final ToolExecutionService toolService;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
}

/// 每个一级导航对应的页面。
Widget buildSectionPage(AppSection section, AppDependencies dependencies) =>
    switch (section) {
      AppSection.home => HomePage(
        taskRepository: dependencies.taskRepository,
      ),
      AppSection.tools => ToolsPage(toolService: dependencies.toolService),
      AppSection.tasks => TasksPage(repository: dependencies.taskRepository),
      AppSection.settings => SettingsPage(
        themeMode: dependencies.themeMode,
        onThemeModeChanged: dependencies.onThemeModeChanged,
      ),
    };

/// Web / 桌面首次加载时解析 URL 中的路由。
///
/// 支持 `#/tools` 这种 hash 深链（端到端测试与刷新都依赖它）；
/// 读不到就回到首页，不抛异常。
String resolveInitialPath(String? platformRoute) {
  var path = (platformRoute ?? '').trim();
  if (path.isEmpty || path == '/') {
    // Flutter Web 默认使用 hash 策略（/app/#/tools），原生端 platformRoute
    // 已经是正常路由名，这里只做兜底，读不到就回首页。
    final fragment = Uri.base.fragment.trim();
    if (fragment.isNotEmpty) path = fragment;
  }
  if (!path.startsWith('/')) path = '/$path';
  return AppSection.fromPath(path).path;
}