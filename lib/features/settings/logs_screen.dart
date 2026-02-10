import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/models/log_entry.dart';
import 'package:vaultsafe/shared/providers/log_provider.dart';

/// 日志类型枚举
enum LogType {
  all,
  system,
  user,
}

/// 日志查看界面
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  late TabController _tabController;
  LogType _selectedLogType = LogType.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedLogType = LogType.values[_tabController.index];
      });
    });
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterLevel = ref.watch(logFilterLevelProvider);
    final stats = ref.watch(logStatisticsProvider);
    final searchQuery = ref.watch(logSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统日志'),
        actions: [
          // 日志级别过滤
          PopupMenuButton<LogLevel>(
            icon: _buildLevelIcon(filterLevel),
            tooltip: '过滤日志级别',
            onSelected: (level) {
              ref.read(logFilterLevelProvider.notifier).state = level;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: LogLevel.debug,
                child: _buildMenuItem(LogLevel.debug, filterLevel),
              ),
              PopupMenuItem(
                value: LogLevel.info,
                child: _buildMenuItem(LogLevel.info, filterLevel),
              ),
              PopupMenuItem(
                value: LogLevel.warning,
                child: _buildMenuItem(LogLevel.warning, filterLevel),
              ),
              PopupMenuItem(
                value: LogLevel.error,
                child: _buildMenuItem(LogLevel.error, filterLevel),
              ),
            ],
          ),
          // 自动滚动开关
          IconButton(
            icon: Icon(_autoScroll ? Icons.arrow_downward : Icons.swap_vert),
            tooltip: _autoScroll ? '自动滚动: 开' : '自动滚动: 关',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
                if (_autoScroll) _scrollToBottom();
              });
            },
          ),
          // 清除日志
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除日志',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除日志'),
                  content: const Text('确定要清除所有日志吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                ref.read(logServiceProvider).clear();
              }
            },
          ),
          // 导出日志
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出日志',
            onPressed: () {
              _showExportDialog(stats['total'] ?? 0);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部日志'),
            Tab(text: '系统日志'),
            Tab(text: '用户操作'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 日志级别统计卡片 - 置顶显示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日志级别图标统计 - 横向排列
                Row(
                  children: [
                    _buildLogLevelChip(
                      context,
                      icon: Icons.bug_report_outlined,
                      label: '调试',
                      count: stats['debug'] ?? 0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _buildLogLevelChip(
                      context,
                      icon: Icons.info_outline,
                      label: '信息',
                      count: stats['info'] ?? 0,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildLogLevelChip(
                      context,
                      icon: Icons.warning_amber_outlined,
                      label: '警告',
                      count: stats['warning'] ?? 0,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildLogLevelChip(
                      context,
                      icon: Icons.error_outline,
                      label: '错误',
                      count: stats['error'] ?? 0,
                      color: Colors.red,
                    ),
                    const Spacer(),
                    // 总数显示
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '总计 ${stats['total'] ?? 0}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 搜索栏
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索日志...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ref.read(logSearchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(logSearchQueryProvider.notifier).state = value;
                  },
                ),
              ],
            )),
          ),
          // 日志列表 - 占满剩余空间
          Expanded(
            child: Builder(
              builder: (context) {
                final baseFilteredLogs = searchQuery.isEmpty
                    ? ref.watch(filteredLogsProvider)
                    : ref.watch(searchedLogsProvider);

                // 根据选择的类型过滤
                final displayLogs = _filterByLogType(baseFilteredLogs);

                if (displayLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isEmpty
                              ? Icons.note_outlined
                              : Icons.search_off,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty ? '暂无日志' : '未找到匹配的日志',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: displayLogs.length,
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    return _LogEntryTile(logEntry: log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 根据日志类型过滤
  List<LogEntry> _filterByLogType(List<LogEntry> logs) {
    switch (_selectedLogType) {
      case LogType.all:
        return logs;
      case LogType.system:
        return logs.where((log) => _isSystemLog(log)).toList();
      case LogType.user:
        return logs.where((log) => !_isSystemLog(log)).toList();
    }
  }

  /// 判断是否为系统日志
  bool _isSystemLog(LogEntry log) {
    final source = log.source?.toLowerCase() ?? '';

    // 系统组件列表
    const systemComponents = [
      'main',
      'storage',
      'authservice',
      'encryption',
      'logservice',
      'log',
      'backup',
      'sync',
      'hive',
      'provider',
    ];

    return systemComponents.any((component) => source.contains(component));
  }

  Widget _buildLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return const Icon(Icons.bug_report_outlined, color: Colors.grey);
      case LogLevel.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case LogLevel.warning:
        return const Icon(Icons.warning_amber_outlined, color: Colors.orange);
      case LogLevel.error:
        return const Icon(Icons.error_outline, color: Colors.red);
    }
  }

  Widget _buildMenuItem(LogLevel level, LogLevel currentLevel) {
    final isSelected = level == currentLevel;
    return Row(
      children: [
        _buildLevelIcon(level),
        const SizedBox(width: 8),
        Text(level.label),
        const Spacer(),
        if (isSelected) const Icon(Icons.check, size: 16),
      ],
    );
  }

  Widget _buildLogLevelChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        // 点击芯片时过滤对应级别
        ref.read(logFilterLevelProvider.notifier).state =
            _levelFromLabel(label);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LogLevel _levelFromLabel(String label) {
    switch (label) {
      case '调试':
        return LogLevel.debug;
      case '信息':
        return LogLevel.info;
      case '警告':
        return LogLevel.warning;
      case '错误':
        return LogLevel.error;
      default:
        return LogLevel.debug;
    }
  }

  void _showExportDialog(int logCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日志总数: $logCount'),
            const SizedBox(height: 16),
            const Text('请选择导出格式:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportLogs(format: 'text');
            },
            child: const Text('文本格式'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportLogs(format: 'json');
            },
            child: const Text('JSON格式'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _exportLogs({required String format}) {
    final logService = ref.read(logServiceProvider);
    logService.exportToText();

    // TODO: 实现文件保存功能
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出功能待实现 (${format.toUpperCase()})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// 日志条目 Tile
class _LogEntryTile extends StatelessWidget {
  final LogEntry logEntry;

  const _LogEntryTile({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: _buildLevelIcon(logEntry.level),
        title: Text(
          logEntry.message,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatSubtitle(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
                fontSize: 10,
              ),
        ),
        trailing: Text(
          _formatTime(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
                fontSize: 10,
              ),
        ),
      ),
    );
  }

  Widget _buildLevelIcon(LogLevel level) {
    Color color;
    IconData icon;

    switch (level) {
      case LogLevel.debug:
        color = Colors.grey;
        icon = Icons.bug_report_outlined;
        break;
      case LogLevel.info:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        icon = Icons.warning_amber_outlined;
        break;
      case LogLevel.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _formatSubtitle() {
    final source = logEntry.source ?? 'Unknown';
    return '[$source] ${logEntry.level.label}';
  }

  String _formatTime() {
    return '${logEntry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${logEntry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${logEntry.timestamp.second.toString().padLeft(2, '0')}';
  }
}
