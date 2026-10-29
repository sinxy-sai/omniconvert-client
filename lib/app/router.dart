import 'package:flutter/material.dart';

import '../core/ocr/ocr_provider.dart';
import '../core/ocr/provider_settings.dart';
import '../core/tasks/task_repository.dart';
import '../core/tools/local_file.dart' as file_picker;
import '../core/tools/tool_execution_service.dart';
import '../features/formula/presentation/formula_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../features/tools/presentation/tools_page.dart';

/// 应用运行期依赖：由 `OmniConvertApp` 构造一次，路由只负责分发。
class AppDependencies {
  const AppDependencies({
    required this.taskRepository,
    required this.toolService,
    required this.ocrProvider,
    required this.providerSettings,
  });

  final TaskRepository taskRepository;
  final ToolExecutionService toolService;
  final OcrProvider? ocrProvider;
  final OcrProviderSettingsStore providerSettings;
}

enum AppDestination {
  home('/', '首页', Icons.home_outlined, Icons.home_rounded),
  formula('/formula', '公式', Icons.functions_outlined, Icons.functions_rounded),
  tasks(
    '/tasks',
    '任务',
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
  ),
  tools('/tools', '工具', Icons.grid_view_outlined, Icons.grid_view_rounded),
  settings(
    '/settings',
    '设置',
    Icons.settings_outlined,
    Icons.settings_rounded,
  );

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

  Widget buildPage(AppDependencies dependencies) => switch (this) {
    AppDestination.home => HomePage(
      taskRepository: dependencies.taskRepository,
    ),
    AppDestination.formula => FormulaPage(
      provider: dependencies.ocrProvider ?? _UnavailableOcrProvider(),
      pickImage: file_picker.pickLocalImage,
      unavailable: dependencies.ocrProvider == null,
    ),
    AppDestination.tasks => TasksPage(repository: dependencies.taskRepository),
    AppDestination.tools => ToolsPage(toolService: dependencies.toolService),
    AppDestination.settings => SettingsPage(
      providerSettings: dependencies.providerSettings,
    ),
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