import 'tool_runner.dart';

class WebToolRunner implements ToolRunner {
  @override
  Future<ToolRunResult> run(
    ToolRequest request, {
    void Function(ToolProgress progress)? onProgress,
  }) => throw const ToolRunException(ToolRunFailure(
    code: 'WebImplementationPending',
    message: '浏览器本地图片处理将在下一阶段开放。',
    retryable: false,
  ));
}

ToolRunner createToolRunner() => WebToolRunner();
