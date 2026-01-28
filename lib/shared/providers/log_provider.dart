import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/shared/models/log_entry.dart';

/// 日志服务 Provider
///
/// 提供对全局日志服务的访问，以及日志状态管理
final logServiceProvider = Provider<LogService>((ref) {
  return LogService.instance;
});

/// 日志列表 Notifier
///
/// 包装日志流，确保初始数据立即可用
class LogListNotifier extends StateNotifier<List<LogEntry>> {
  LogListNotifier(this._logService) : super(_logService.logs.reversed.toList()) {
    // 订阅日志流，自动更新状态
    _subscription = _logService.logsStream.listen(
      (logs) {
        if (!mounted) return;
        // 按时间倒序排列（最新的在最前面）
        state = logs.reversed.toList();
      },
      onError: (error) {
        if (!mounted) return;
        // 发生错误时保持当前状态，不中断 UI
      },
    );
  }

  final LogService _logService;
  StreamSubscription<List<LogEntry>>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// 日志列表 Provider
///
/// 使用 StateNotifier 确保初始数据立即可用，避免 UI 一直处于 loading 状态
final logsProvider = StateNotifierProvider<LogListNotifier, List<LogEntry>>((ref) {
  final logService = ref.watch(logServiceProvider);
  return LogListNotifier(logService);
});

/// 日志过滤器级别 Provider
final logFilterLevelProvider = StateProvider<LogLevel>((ref) {
  return LogLevel.debug;
});

/// 已过滤的日志列表 Provider
///
/// 根据选择的级别过滤日志，日志已按时间倒序排列
final filteredLogsProvider = Provider<List<LogEntry>>((ref) {
  final filterLevel = ref.watch(logFilterLevelProvider);
  final logs = ref.watch(logsProvider);

  if (filterLevel == LogLevel.debug) {
    return logs;
  }
  return logs.where((log) => log.level.severity >= filterLevel.severity).toList();
});

/// 日志统计信息 Provider
final logStatisticsProvider = Provider<Map<String, int>>((ref) {
  final logService = ref.watch(logServiceProvider);
  return logService.getStatistics();
});

/// 日志搜索查询 Provider
final logSearchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索后的日志列表 Provider
final searchedLogsProvider = Provider<List<LogEntry>>((ref) {
  final query = ref.watch(logSearchQueryProvider);
  final logs = ref.watch(filteredLogsProvider);

  if (query.isEmpty) {
    return logs;
  }

  final lowerQuery = query.toLowerCase();
  return logs.where((log) {
    return log.message.toLowerCase().contains(lowerQuery) ||
        (log.source?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
});
