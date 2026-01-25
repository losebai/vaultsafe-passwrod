import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/passwords/passwords_screen.dart';
import 'package:vaultsafe/features/settings/settings_screen.dart';
import 'package:vaultsafe/features/home/sync_screen.dart';
import 'package:vaultsafe/features/home/settings_layout.dart';
import 'package:vaultsafe/shared/providers/log_provider.dart';
import 'package:vaultsafe/shared/models/log_entry.dart';
import 'package:vaultsafe/components/NavigationMenu.dart';

/// 日志类型枚举（与 logs_screen.dart 保持一致）
enum LogType {
  all,
  system,
  user,
}

/// 主界面 - 响应式导航（桌面端侧边栏，移动端底部导航）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = true;

  late final List<Widget> _screens = [
    const PasswordsScreen(),
    const SettingsScreen(),
  ];

  final List<_NavigationItem> _navItems = const [
    _NavigationItem(
      icon: Icons.password_rounded,
      selectedIcon: Icons.password_rounded,
      label: '密码',
    ),
    _NavigationItem(
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
      label: '操作日志',
    ),
    _NavigationItem(
      icon: Icons.sync_rounded,
      selectedIcon: Icons.sync_rounded,
      label: '同步',
    ),
    _NavigationItem(
      icon: Icons.settings_rounded,
      selectedIcon: Icons.settings_rounded,
      label: '设置',
    ),
  ];

  // 检测是否为桌面平台
  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 桌面端使用网格布局
    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 侧边栏
            _buildSideBar(),
            // 主内容区域 - 网格卡片布局
            Expanded(
              child: _buildDesktopContent(context, theme),
            ),
          ],
        ),
      );
    }

    // 移动端使用底部导航栏
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  // 构建桌面端主要内容区域
  Widget _buildDesktopContent(BuildContext context, ThemeData theme) {
    switch (_selectedIndex) {
      case 0: // 密码
        return _buildPasswordsContent();
      case 1: // 操作日志
        return _buildLogsContent(context);
      case 2: // 同步
        return _buildSyncContent(context);
      case 3: // 设置
        return _buildSettingsContent(context);
      default:
        return _screens[_selectedIndex];
    }
  }

  // 构建密码页面内容
  Widget _buildPasswordsContent() {
    return const PasswordsScreen();
  }

  // 构建操作日志内容
  Widget _buildLogsContent(BuildContext context) {
    return const _LogsLayout();
  }

  // 构建同步内容
  Widget _buildSyncContent(BuildContext context) {
    return const SyncScreen();
  }

  // 构建设置内容 - 简化版
  Widget _buildSettingsContent(BuildContext context) {
    return const SettingsLayout();
  }

  // 构建桌面端侧边栏
  Widget _buildSideBar() {
    final width = _isCollapsed ? 72.0 : 170.0;
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部 Logo 区域
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'VaultSafe',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 18),
                  ),
                ],
              ],
            ),
          ),

          // 导航菜单
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return _buildNavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                );
              },
            ),
          ),

          // 底部收缩按钮
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() => _isCollapsed = !_isCollapsed);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建导航项
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? 8 : 12,
        vertical: 4,
      ),
      child: NavigationMenu(
        icon: icon,
        label: label,
        onTap: onTap,
        isSelected: isSelected,
        isCollapsed: _isCollapsed,
      ),
    );
  }
}

/// 导航项数据模型
class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 操作日志布局
class _LogsLayout extends ConsumerStatefulWidget {
  const _LogsLayout();

  @override
  ConsumerState<_LogsLayout> createState() => _LogsLayoutState();
}

class _LogsLayoutState extends ConsumerState<_LogsLayout>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和统计区域 - 固定在顶部
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '敏感操作日志',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 72, 120),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '记录所有敏感操作，包括查看、添加、编辑和删除密码',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // TabBar
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: '全部日志'),
                    Tab(text: '系统日志'),
                    Tab(text: '用户操作'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 日志列表 - 占满剩余空间
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(32),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Builder(
              builder: (context) {
                final filteredLogs = ref.watch(filteredLogsProvider);
                // 根据选择的类型过滤
                final displayLogs = _filterByLogType(filteredLogs);

                if (displayLogs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无操作日志',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 使用 ListView 让日志列表可滚动，显示所有日志
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayLogs.length,
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    return _buildLogItem(
                      theme,
                      icon: _getIconForLogLevel(log.level),
                      title: _getTitleForLogLevel(log.level),
                      description: log.message,
                      time: _formatTime(log.timestamp),
                      color: _getColorForLogLevel(log.level),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
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

  IconData _getIconForLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_outlined;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  String _getTitleForLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '调试';
      case LogLevel.info:
        return '信息';
      case LogLevel.warning:
        return '警告';
      case LogLevel.error:
        return '错误';
    }
  }

  Color _getColorForLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Widget _buildLogItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
