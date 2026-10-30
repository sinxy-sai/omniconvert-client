/// 面向用户的错误文案（中文、可读、不直接暴露 Dart 异常/英文堆栈）。
///
/// 原则：
/// 1. 先说「发生了什么」，再说「可以怎么办」；
/// 2. 错误码只作为可折叠的技术细节，不放在主文案里；
/// 3. 同一句话不要在标题和正文里重复。
String toolErrorHint(String? code) {
  final normalized = (code ?? '').toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'cancelled' || 'canceled' => '任务已取消，没有写入任何文件。',
    'inputtoolarge' || 'input_too_large' || 'file_too_large' =>
      '文件超过大小限制，请换一个更小的文件。',
    'invalidinput' ||
    'invalid_input' ||
    'decode_failed' ||
    'unsupported_media' => '无法读取这个文件，可能已损坏、被加密，或格式与所选工具不匹配。',
    'unsupported_tool' || 'unsupportedtool' =>
      '当前平台暂不支持这个工具，可以换一个工具试试。',
    'inputbytesrequired' || 'input_bytes_required' =>
      '浏览器端处理需要先在页面上选择文件。',
    'converterunavailable' ||
    'converter_unavailable' ||
    'backend_unavailable' ||
    'network_error' ||
    'networkerror' ||
    'timeout' ||
    'http_error' ||
    'server_error' => '转换服务暂时不可用，请稍后重试；文件仍在你的设备上。',
    'write_failed' ||
    'writefailed' ||
    'io_error' ||
    'ioerror' ||
    'permission_denied' => '无法写入输出文件，请检查磁盘空间和写入权限。',
    '' => '处理没有完成，请重试一次。',
    _ => '处理没有完成，请重试或换一个文件。',
  };
}

/// 失败后建议的下一步动作（按钮文案用）。
String toolErrorAction(String? code) {
  final normalized = (code ?? '').toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'inputtoolarge' || 'input_too_large' || 'file_too_large' => '换一个文件',
    'invalidinput' || 'invalid_input' || 'decode_failed' => '换一个文件',
    'converterunavailable' ||
    'converter_unavailable' ||
    'network_error' ||
    'networkerror' ||
    'timeout' => '重试一次',
    _ => '重试一次',
  };
}

/// 真正意外（非业务异常）时的兜底文案。
const genericErrorHint = '出了点问题，请重试一次；如果持续出现，可以展开技术详情反馈给我们。';

/// 网络/更新检查的兜底文案。
const updateCheckErrorHint = '暂时无法连接更新服务，请稍后重试。';

/// 界面层拒绝文件时的可读原因（不暴露异常）。
String rejectionHint({
  required String? reason,
  required List<String> acceptedExtensions,
  int? maxBytes,
}) {
  final formats = acceptedExtensions
      .map((extension) => extension.toUpperCase())
      .join(' · ');
  return switch (reason) {
    'extension' => '这个文件不是支持的格式，请选择 $formats 文件。',
    'size' => '文件太大了，请换一个更小的文件${maxBytes == null ? '' : '（上限见拖拽区）'}。',
    'empty' => '这个文件是空的，换一个文件试试。',
    'multiple' => '一次只能处理一个文件，已使用第一个。',
    _ => '这个文件暂时不能处理，换一个试试。',
  };
}