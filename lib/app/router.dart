import 'package:flutter/material.dart';

import '../core/ocr/ocr_provider.dart';
import '../core/tools/file_picker_stub.dart'
    if (dart.library.html) '../core/tools/file_picker_web.dart'
    as file_picker;
import '../core/tasks/task_repository.dart';
import '../core/tools/tool_execution_service.dart';
import '../features/home/presentation/home_page.dart';
import '../features/formula/presentation/formula_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../features/tools/presentation/tools_page.dart';

enum AppDestination {
  home('/', '首页', Icons.home_outlined, Icons.home_rounded),
  formula('/formula', '公式', Icons.functions_outlined, Icons.functions),
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

  Widget buildPage(
    TaskRepository taskRepository,
    ToolExecutionService toolService,
  ) => switch (this) {
    AppDestination.home => HomePage(taskRepository: taskRepository),
    AppDestination.formula => FormulaPage(
      provider: _UnavailableOcrProvider(),
      pickImage: file_picker.pickLocalImage,
    ),
    AppDestination.tasks => const TasksPage(),
    AppDestination.tools => ToolsPage(toolService: toolService),
    AppDestination.settings => const SettingsPage(),
  };
}

class _UnavailableOcrProvider implements OcrProvider {
  @override
  Future<OcrCapabilities> capabilities() =>
      Future.error(const OcrProviderException('not_configured', '请先配置识别服务'));

  @override
  Future<OcrResult> recognize(
    List<int> image, {
    required String mode,
    required String idempotencyKey,
    Duration timeout = const Duration(seconds: 20),
  }) => Future.error(const OcrProviderException('not_configured', '请先配置识别服务'));
}
