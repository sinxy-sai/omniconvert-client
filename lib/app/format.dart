/// 一小组纯函数格式化工具（不引入 intl，保持依赖最小）。
String formatFileSize(int bytes) {
  if (bytes < 0) return '—';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${_trim(kb)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${_trim(mb)} MB';
  return '${_trim(mb / 1024)} GB';
}

String _trim(double value) {
  final fixed = value >= 100
      ? value.toStringAsFixed(0)
      : value >= 10
      ? value.toStringAsFixed(1)
      : value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// 相对时间：刚刚 / N 分钟前 / N 小时前 / 昨天 HH:mm / MM-DD HH:mm。
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final diff = current.difference(local);
  if (diff.isNegative) return _clock(local);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24 && local.day == current.day) {
    return '${diff.inHours} 小时前';
  }
  final yesterday = DateTime(current.year, current.month, current.day - 1);
  if (local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day) {
    return '昨天 ${_clock(local)}';
  }
  final sameYear = local.year == current.year;
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return sameYear
      ? '$month-$day ${_clock(local)}'
      : '${local.year}-$month-$day';
}

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// 任务耗时（秒级），用于成功任务卡片。
String formatDuration(Duration duration) {
  if (duration.inSeconds < 1) return '< 1 秒';
  if (duration.inSeconds < 60) return '${duration.inSeconds} 秒';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes 分 $seconds 秒';
}