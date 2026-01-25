/// 日志级别枚举
enum LogLevel {
  debug('DEBUG', 0),
  info('INFO', 1),
  warning('WARNING', 2),
  error('ERROR', 3);

  final String label;
  final int severity;

  const LogLevel(this.label, this.severity);
}

/// 日志条目模型
class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? source; // 日志来源（如：StorageService, AuthService等）

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.source,
  });

  /// 创建调试日志
  factory LogEntry.debug(String message, {String? source}) {
    return LogEntry(
      message: message,
      level: LogLevel.debug,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  /// 创建信息日志
  factory LogEntry.info(String message, {String? source}) {
    return LogEntry(
      message: message,
      level: LogLevel.info,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  /// 创建警告日志
  factory LogEntry.warning(String message, {String? source}) {
    return LogEntry(
      message: message,
      level: LogLevel.warning,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  /// 创建错误日志
  factory LogEntry.error(String message, {String? source}) {
    return LogEntry(
      message: message,
      level: LogLevel.error,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  /// 格式化日志为文本
  String format({bool includeSource = true}) {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}'
        '.${timestamp.millisecond.toString().padLeft(3, '0')}';

    final sourceStr = includeSource && source != null ? '[$source] ' : '';
    return '$timeStr ${level.label.padRight(7)} $sourceStr$message';
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.label,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  /// 从JSON创建
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      message: json['message'] as String,
      level: LogLevel.values.firstWhere(
        (e) => e.label == json['level'],
        orElse: () => LogLevel.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String?,
    );
  }

  /// 复制并修改部分字段
  LogEntry copyWith({
    String? message,
    LogLevel? level,
    DateTime? timestamp,
    String? source,
  }) {
    return LogEntry(
      message: message ?? this.message,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }
}
