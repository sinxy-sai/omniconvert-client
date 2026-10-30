import 'tool_runner.dart';

/// The only error codes OmniConvert Core ever surfaces to the UI.
///
/// Every failure path — pure Dart image tools, the HTTP conversion backend and
/// the update pipeline — is normalised into one of these six codes so the UI
/// only needs a single switch to render a readable Chinese hint.
abstract final class ToolErrorCode {
  /// The input could not be read at all: corrupt, truncated, encrypted, or a
  /// format that does not match the selected tool.
  static const String invalidInput = 'InvalidInput';

  /// The input exceeds the size or pixel budget declared by the registry.
  static const String inputTooLarge = 'InputTooLarge';

  /// The tool id is unknown, or the current platform cannot run it.
  static const String unsupportedTool = 'UnsupportedTool';

  /// The user cancelled the task.
  static const String cancelled = 'Cancelled';

  /// The server-side converter is reachable but cannot convert right now
  /// (HTTP 5xx, timeouts, server busy).
  static const String converterUnavailable = 'ConverterUnavailable';

  /// No usable network response at all (DNS, TLS, connection refused, offline).
  static const String networkError = 'NetworkError';
}

/// Canonical codes as a set, used by tests and defensive validation.
const Set<String> kToolErrorCodes = <String>{
  ToolErrorCode.invalidInput,
  ToolErrorCode.inputTooLarge,
  ToolErrorCode.unsupportedTool,
  ToolErrorCode.cancelled,
  ToolErrorCode.converterUnavailable,
  ToolErrorCode.networkError,
};

/// Readable Chinese copy for every canonical code.
///
/// The message always states *what happened*; the UI is responsible for adding
/// the "what can I do now" affordance.
String toolErrorMessage(String code) => switch (code) {
  ToolErrorCode.invalidInput =>
    '无法读取这个文件，可能已损坏、被加密，或格式与所选工具不匹配。',
  ToolErrorCode.inputTooLarge => '文件超出大小限制，请换一个更小的文件。',
  ToolErrorCode.unsupportedTool => '当前平台暂不支持这个工具，可以换一个工具试试。',
  ToolErrorCode.cancelled => '任务已取消，没有写入任何文件。',
  ToolErrorCode.converterUnavailable => '文档转换服务暂时不可用，请稍后重试；文件仍在你自己的设备上。',
  ToolErrorCode.networkError => '无法连接服务器，请检查网络后重试。',
  _ => '处理没有完成，请重试一次。',
};

/// Normalises any provider/Vendor supplied code (snake_case, kebab-case, plain
/// lowercase, or a canonical `PascalCase` code) into a canonical code.
///
/// Returns `null` when the code is unknown, so the caller can fall back to a
/// transport-level signal such as the HTTP status.
String? canonicalToolErrorCode(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final key = value.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  return switch (key) {
    'invalidinput' ||
    'invalid_input' ||
    'decode_failed' ||
    'undecodable' ||
    'unsupported_media' ||
    'bad_request' ||
    'invalid_pdf' ||
    'corrupt_input' => ToolErrorCode.invalidInput,
    'inputtoolarge' ||
    'input_too_large' ||
    'file_too_large' ||
    'payload_too_large' ||
    'request_too_large' ||
    'too_large' ||
    'too_many_pixels' => ToolErrorCode.inputTooLarge,
    'unsupportedtool' ||
    'unsupported_tool' ||
    'unsupported_format' ||
    'invalid_tool' ||
    'unknown_tool' ||
    'not_supported' => ToolErrorCode.unsupportedTool,
    'cancelled' || 'canceled' || 'aborted' => ToolErrorCode.cancelled,
    'converterunavailable' ||
    'conversionunavailable' ||
    'converter_unavailable' ||
    'conversion_unavailable' ||
    'conversion_failed' ||
    'conversion_timeout' ||
    'timeout' ||
    'server_busy' ||
    'rate_limited' ||
    'too_many_requests' ||
    'internal_error' ||
    'server_error' ||
    'service_unavailable' => ToolErrorCode.converterUnavailable,
    'networkerror' ||
    'network_error' ||
    'connection_failed' ||
    'connection_refused' ||
    'dns_error' ||
    'offline' ||
    'tls_error' => ToolErrorCode.networkError,
    _ => null,
  };
}

/// Maps an HTTP status plus an optional backend `x-error-code` header to a
/// canonical failure with readable Chinese copy.
ToolRunFailure conversionFailureFor({
  required int statusCode,
  String? serverCode,
  String? detail,
}) {
  final explicit = canonicalToolErrorCode(serverCode);
  final code =
      explicit ??
      switch (statusCode) {
        413 => ToolErrorCode.inputTooLarge,
        415 => ToolErrorCode.unsupportedTool,
        // Server side capacity/timeouts are "try again later", not bad input.
        408 || 429 || 504 => ToolErrorCode.converterUnavailable,
        >= 400 && < 500 => ToolErrorCode.invalidInput,
        _ => ToolErrorCode.converterUnavailable,
      };
  final base = toolErrorMessage(code);
  final trimmed = detail?.trim() ?? '';
  // Server messages are useful but must never leak stack traces or raw JSON.
  final safeDetail =
      trimmed.isEmpty || trimmed.length > 200 || trimmed.contains(RegExp(r'Traceback|Exception|^\s*[{[]'))
      ? null
      : trimmed;
  return ToolRunFailure(
    code: code,
    message: safeDetail == null ? base : '$base（服务端说明：$safeDetail）',
  );
}

/// Convenience constructors so every throw site stays consistent.
ToolRunFailure invalidInputFailure([String? detail]) => ToolRunFailure(
  code: ToolErrorCode.invalidInput,
  message: detail ?? toolErrorMessage(ToolErrorCode.invalidInput),
);

ToolRunFailure inputTooLargeFailure([String? detail]) => ToolRunFailure(
  code: ToolErrorCode.inputTooLarge,
  message: detail ?? toolErrorMessage(ToolErrorCode.inputTooLarge),
);

ToolRunFailure unsupportedToolFailure([String? detail]) => ToolRunFailure(
  code: ToolErrorCode.unsupportedTool,
  message: detail ?? toolErrorMessage(ToolErrorCode.unsupportedTool),
);

ToolRunFailure cancelledFailure() => ToolRunFailure(
  code: ToolErrorCode.cancelled,
  message: toolErrorMessage(ToolErrorCode.cancelled),
);