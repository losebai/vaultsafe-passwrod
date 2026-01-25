import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vaultsafe/shared/models/log_entry.dart';

/// 全局日志服务
///
/// 单例模式，用于收集和管理应用程序的所有日志输出
class LogService {
  // 单例模式
  LogService._internal() {
    // 初始化时发出当前日志列表（即使是空的），确保监听者能收到初始数据
    _notifyListeners();
  }
  static final LogService _instance = LogService._internal();
  static LogService get instance => _instance;

  // 日志流控制器
  final StreamController<List<LogEntry>> _logsController =
      StreamController<List<LogEntry>>.broadcast();

  // 日志列表
  final List<LogEntry> _logs = [];

  // 最大日志数量
  static const int _maxLogs = 1000;

  // 日志级别过滤器
  LogLevel _filterLevel = LogLevel.debug;

  // 是否启用日志
  bool _isEnabled = true;

  /// 日志流，用于UI监听日志更新
  Stream<List<LogEntry>> get logsStream => _logsController.stream;

  /// 当前所有日志列表
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// 日志过滤器级别
  LogLevel get filterLevel => _filterLevel;
  set filterLevel(LogLevel level) {
    _filterLevel = level;
    _notifyListeners();
  }

  /// 是否启用日志
  bool get isEnabled => _isEnabled;

  /// 启用日志
  void enable() {
    _isEnabled = true;
    add(LogEntry.info('日志服务已启用', source: 'LogService'));
  }

  /// 禁用日志
  void disable() {
    _isEnabled = false;
  }

  /// 添加日志条目
  void add(LogEntry entry) {
    if (!_isEnabled) return;

    // 检查日志级别
    if (entry.level.severity < _filterLevel.severity) {
      return;
    }

    // 添加到列表
    _logs.add(entry);

    // 限制日志数量
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // 输出到控制台
    if (kDebugMode) {
      debugPrint(entry.format());
    }

    // 通知监听器
    _notifyListeners();
  }

  /// 添加调试日志
  void d(String message, {String? source}) {
    add(LogEntry.debug(message, source: source));
  }

  /// 添加信息日志
  void i(String message, {String? source}) {
    add(LogEntry.info(message, source: source));
  }

  /// 添加警告日志
  void w(String message, {String? source}) {
    add(LogEntry.warning(message, source: source));
  }

  /// 添加错误日志
  void e(String message, {String? source, Object? error, StackTrace? stackTrace}) {
    final buffer = StringBuffer(message);

    if (error != null) {
      buffer.write('\n错误: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n堆栈:\n$stackTrace');
    }

    add(LogEntry.error(buffer.toString(), source: source));
  }

  /// 清除所有日志
  void clear() {
    _logs.clear();
    _notifyListeners();
    add(LogEntry.info('日志已清除', source: 'LogService'));
  }

  /// 导出所有日志为文本
  String exportToText() {
    final buffer = StringBuffer();
    buffer.writeln('=== VaultSafe 日志导出 ===');
    buffer.writeln('导出时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('日志总数: ${_logs.length}');
    buffer.writeln('');

    for (final log in _logs) {
      buffer.writeln(log.format());
    }

    return buffer.toString();
  }

  /// 导出所有日志为JSON
  String exportToJson() {
    final jsonList = _logs.map((e) => e.toJson()).toList();
    return '''
{
  "exportedAt": "${DateTime.now().toIso8601String()}",
  "totalLogs": ${_logs.length},
  "logs": ${jsonList.map((e) => e.toString()).join(',')}
}
''';
  }

  /// 根据来源过滤日志
  List<LogEntry> filterBySource(String source) {
    return _logs.where((log) => log.source == source).toList();
  }

  /// 根据级别过滤日志
  List<LogEntry> filterByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList()

;
  }

  /// 根据时间范围过滤日志
  List<LogEntry> filterByTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) {
      return log.timestamp.isAfter(start) && log.timestamp.isBefore(end);
    }).toList();
  }

  /// 搜索日志
  List<LogEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      return log.message.toLowerCase().contains(lowerQuery) ||
          (log.source?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 获取日志统计信息
  Map<String, int> getStatistics() {
    final stats = <String, int>{
      'total': _logs.length,
      'debug': 0,
      'info': 0,
      'warning': 0,
      'error': 0,
    };

    for (final log in _logs) {
      stats[log.level.label.toLowerCase()] =
          stats[log.level.label.toLowerCase()]! + 1;
    }

    return stats;
  }

  /// 通知监听器
  void _notifyListeners() {
    if (!_logsController.isClosed) {
      _logsController.add(List.unmodifiable(_logs));
    }
  }

  /// 释放资源
  void dispose() {
    _logsController.close();
  }
}

/// 全局日志实例，方便在任何地方调用
final log = LogService.instance;

/// 便捷的日志函数
void logDebug(String message, {String? source}) => log.d(message, source: source);
void logInfo(String message, {String? source}) => log.i(message, source: source);
void logWarning(String message, {String? source}) => log.w(message, source: source);
void logError(String message, {String? source, Object? error, StackTrace? stackTrace}) =>
    log.e(message, source: source, error: error, stackTrace: stackTrace);
