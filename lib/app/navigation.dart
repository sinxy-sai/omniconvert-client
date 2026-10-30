import 'icons/oc_icons.dart';

/// 一级导航：4 项（首页 / 工具 / 任务 / 设置）。
///
/// 本轮产品范围明确不做 OCR，因此「公式识别」不再出现在导航里。
enum AppSection {
  home('/', '首页', OcIcons.home),
  tools('/tools', '工具', OcIcons.tools),
  tasks('/tasks', '任务', OcIcons.tasks),
  settings('/settings', '设置', OcIcons.settings);

  const AppSection(this.path, this.label, this.icon);

  final String path;
  final String label;
  final OcIconData icon;

  static AppSection fromPath(String? path) => AppSection.values.firstWhere(
    (section) => section.path == path,
    orElse: () => AppSection.home,
  );
}