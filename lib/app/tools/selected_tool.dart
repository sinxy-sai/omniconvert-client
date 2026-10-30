/// 跨页面传递「这次要打开哪个工具」的最小状态。
///
/// 首页的「工具速用」点进来时设置，工具页 initState 里消费一次即清空；
/// 不引入全局状态管理框架，也不污染路由参数。
abstract final class ToolSelection {
  static String? _pending;

  static void request(String toolId) => _pending = toolId;

  static String? take() {
    final pending = _pending;
    _pending = null;
    return pending;
  }
}