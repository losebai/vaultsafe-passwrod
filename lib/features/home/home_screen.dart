import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaultsafe/features/passwords/passwords_screen.dart';
import 'package:vaultsafe/features/settings/settings_screen.dart';
import 'package:vaultsafe/shared/models/sync_config.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

import 'package:vaultsafe/components/NavigationMenu.dart';

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
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

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
    return const _SyncLayout();
  }

  // 构建设置内容 - 简化版
  Widget _buildSettingsContent(BuildContext context) {
    return const _SettingsLayout();
  }

  // 构建桌面端侧边栏
  Widget _buildSideBar() {
    final width = _isCollapsed ? 72.0 : 150.0;
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
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                      fontSize: 25
                    ),
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
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _isCollapsed
                        ? Icons.chevron_right
                        : Icons.chevron_left,
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
class _LogsLayout extends StatelessWidget {
  const _LogsLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
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
          const SizedBox(height: 16),
          Text(
            '记录所有敏感操作，包括查看、添加、编辑和删除密码',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // 日志列表
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildLogItem(
                  theme,
                  icon: Icons.visibility_outlined,
                  title: '查看密码',
                  description: '查看了 Google 账号的密码',
                  time: '2 分钟前',
                  color: const Color.fromARGB(255, 33, 150, 243),
                ),
                const Divider(height: 1, indent: 72),
                _buildLogItem(
                  theme,
                  icon: Icons.edit_outlined,
                  title: '编辑密码',
                  description: '修改了 GitHub 账号的密码',
                  time: '15 分钟前',
                  color: const Color.fromARGB(255, 255, 152, 0),
                ),
                const Divider(height: 1, indent: 72),
                _buildLogItem(
                  theme,
                  icon: Icons.add_circle_outline,
                  title: '添加密码',
                  description: '添加了新的密码：Twitter 账号',
                  time: '1 小时前',
                  color: const Color.fromARGB(255, 76, 175, 80),
                ),
                const Divider(height: 1, indent: 72),
                _buildLogItem(
                  theme,
                  icon: Icons.delete_outline,
                  title: '删除密码',
                  description: '删除了旧的测试密码',
                  time: '昨天 14:30',
                  color: const Color.fromARGB(255, 244, 67, 54),
                ),
                const Divider(height: 1, indent: 72),
                _buildLogItem(
                  theme,
                  icon: Icons.file_download_outlined,
                  title: '导出备份',
                  description: '导出了加密备份文件',
                  time: '昨天 10:15',
                  color: const Color.fromARGB(255, 156, 39, 176),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

/// 同步布局
class _SyncLayout extends StatefulWidget {
  const _SyncLayout();

  @override
  State<_SyncLayout> createState() => _SyncLayoutState();
}

class _SyncLayoutState extends State<_SyncLayout> {
  bool _isSyncing = false;
  String? _syncError;
  DateTime? _lastSyncTime;

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      // TODO: 实现实际的同步逻辑
      await Future.delayed(const Duration(seconds: 2)); // 模拟同步

      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncError = e.toString();
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    }
  }

  void _showSyncConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const _SyncConfigDialog(),
    );
  }

  void _showSyncHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步帮助'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '同步协议说明',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'VaultSafe 使用端到端加密同步，您的数据在传输和存储时始终处于加密状态。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              const Text(
                'API 接口规范',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text('上传数据 (POST):', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'POST /api/v1/sync\n'
                  'Authorization: Bearer <token>\n'
                  'Content-Type: application/json\n\n'
                  '{\n'
                  '  "device_id": "uuid-string",\n'
                  '  "timestamp": 1705742400,\n'
                  '  "encrypted_data": "base64(AES-GCM(...))",\n'
                  '  "version": "1.0"\n'
                  '}',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              const Text('下载数据 (GET):', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GET /api/v1/sync\n'
                  'Authorization: Bearer <token>\n\n'
                  '响应:\n'
                  '{\n'
                  '  "device_id": "other-device-id",\n'
                  '  "timestamp": 1705742500,\n'
                  '  "encrypted_data": "base64(...)",\n'
                  '  "version": "1.0"\n'
                  '}',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '配置示例',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              _buildExampleItem(
                '自建服务器',
                'https://your-server.com/api/v1/sync',
                'Bearer Token',
              ),
              _buildExampleItem(
                'WebDAV (Nextcloud)',
                'https://nextcloud.com/remote.php/dav/files/user/vaultsafe.json',
                'Basic Auth',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(String title, String endpoint, String auth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            '端点: $endpoint',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '认证: $auth',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行，包含帮助按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  '同步与备份',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 72, 120),
                  ),
                ),
              ),
              IconButton(
                onPressed: _showSyncHelpDialog,
                icon: const Icon(Icons.help_outline),
                tooltip: '同步帮助',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '管理数据同步和备份',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 72, 120).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_outlined,
                          color: Color.fromARGB(255, 0, 72, 120),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '同步配置',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _syncError ?? '未配置同步服务器',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _syncError != null
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _showSyncConfigDialog,
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('配置'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        _lastSyncTime != null ? Icons.cloud_done : Icons.cloud_off,
                        size: 20,
                        color: _lastSyncTime != null
                            ? const Color.fromARGB(255, 76, 175, 80)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _lastSyncTime != null
                            ? '上次同步: ${_formatDateTime(_lastSyncTime!)}'
                            : '未同步',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isSyncing ? null : _performSync,
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync, size: 18),
                        label: Text(_isSyncing ? '同步中...' : '立即同步'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 导入导出
          _buildSettingsCard(
            theme,
            title: '导入导出',
            icon: Icons.swap_vert_outlined,
            items: [
              _SettingsItem(
                icon: Icons.download_outlined,
                title: '导出备份',
                description: '下载加密备份文件',
                onTap: () {
                  _showExportDialog();
                },
              ),
              _SettingsItem(
                icon: Icons.upload_outlined,
                title: '导入备份',
                description: '从备份文件恢复数据',
                onTap: () {
                  _showImportDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出备份'),
        content: const Text('是否导出当前所有密码的加密备份？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现导出逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导出功能开发中...')),
              );
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入备份'),
        content: const Text('从备份文件恢复数据将覆盖现有数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现导入逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导入功能开发中...')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<_SettingsItem> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 72, 120).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromARGB(255, 0, 72, 120),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.trailing != null)
                            item.trailing!
                          else
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (item != items.last) const Divider(height: 1, indent: 56),
                ],
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 同步配置对话框
class _SyncConfigDialog extends StatefulWidget {
  const _SyncConfigDialog();

  @override
  State<_SyncConfigDialog> createState() => _SyncConfigDialogState();
}

class _SyncConfigDialogState extends State<_SyncConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _endpointController;
  late final TextEditingController _tokenController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  SyncAuthType _authType = SyncAuthType.bearer;
  SyncInterval _interval = SyncInterval.none;
  bool _isEnabled = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController();
    _tokenController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_endpointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入同步端点')),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      final dio = Dio();
      await dio.get(
        _endpointController.text,
        options: Options(
          headers: _buildTestHeaders(),
        ),
      );

      if (mounted) {
        setState(() => _isTesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接测试成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接测试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, String> _buildTestHeaders() {
    switch (_authType) {
      case SyncAuthType.bearer:
        if (_tokenController.text.isNotEmpty) {
          return {'Authorization': 'Bearer ${_tokenController.text}'};
        }
        break;
      case SyncAuthType.basic:
        if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
          final credentials = base64.encode(
            utf8.encode('${_usernameController.text}:${_passwordController.text}'),
          );
          return {'Authorization': 'Basic $credentials'};
        }
        break;
      case SyncAuthType.custom:
        // Custom headers would be built here
        break;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('配置同步'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 启用同步
              SwitchListTile(
                title: const Text('启用云同步'),
                subtitle: const Text('在设备间同步加密数据'),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() => _isEnabled = value);
                },
              ),
              const SizedBox(height: 16),

              // 同步端点
              TextFormField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: '同步端点',
                  hintText: 'https://your-server.com/api/v1/sync',
                  prefixIcon: Icon(Icons.http),
                ),
                enabled: _isEnabled,
              ),
              const SizedBox(height: 16),

              // 认证方式
              DropdownButtonFormField<SyncAuthType>(
                initialValue: _authType,
                decoration: const InputDecoration(
                  labelText: '认证方式',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                items: SyncAuthType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: _isEnabled ? (value) {
                  setState(() => _authType = value!);
                } : null,
              ),
              const SizedBox(height: 16),

              // 根据认证类型显示不同字段
              if (_authType == SyncAuthType.bearer) ...[
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Bearer Token',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  enabled: _isEnabled,
                ),
              ] else if (_authType == SyncAuthType.basic) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: _isEnabled,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  enabled: _isEnabled,
                ),
              ],

              const SizedBox(height: 16),

              // 同步间隔
              DropdownButtonFormField<SyncInterval>(
                initialValue: _interval,
                decoration: const InputDecoration(
                  labelText: '自动同步间隔',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: SyncInterval.values.map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text(interval.label),
                  );
                }).toList(),
                onChanged: _isEnabled ? (value) {
                  setState(() => _interval = value!);
                } : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        OutlinedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_find, size: 18),
          label: const Text('测试连接'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              // TODO: 保存配置
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('配置已保存')),
              );
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.trailing,
  });
}

/// 设置布局 - 简洁版
class _SettingsLayout extends ConsumerWidget {
  const _SettingsLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '设置',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 72, 120),
                ),
              ),
              const SizedBox(height: 32),

              // 安全设置
              _buildSettingsCard(
                theme,
                title: '安全设置',
                icon: Icons.security_outlined,
                items: [
                  _SettingsItem(
                    icon: Icons.lock_reset,
                    title: '修改主密码',
                    description: '更改您的访问密码',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.timer_outlined,
                    title: '自动锁定',
                    description: _formatTimeout(settings.autoLockTimeout),
                    onTap: () => _showTimeoutDialog(context, ref, settings.autoLockTimeout),
                    trailing: Text(
                      _formatTimeout(settings.autoLockTimeout),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 数据存储
              _buildSettingsCard(
                theme,
                title: '数据存储',
                icon: Icons.storage_outlined,
                items: [
                  _SettingsItem(
                    icon: Icons.folder_outlined,
                    title: '数据存储目录',
                    description: settings.dataDirectory,
                    onTap: () => _showDataDirectoryDialog(context, ref, settings.dataDirectory),
                    trailing: Text(
                      '更改',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 外观设置
              _buildSettingsCard(
                theme,
                title: '外观',
                icon: Icons.palette_outlined,
                items: const [
                  _SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: '深色模式',
                    description: '切换深色/浅色主题',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载设置失败: $error')),
    );
  }

  Widget _buildSettingsCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<_SettingsItem> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 72, 120).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromARGB(255, 0, 72, 120),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          if (item.trailing != null)
                            item.trailing!
                          else
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (item != items.last) const Divider(height: 1, indent: 56),
                ],
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDataDirectoryDialog(BuildContext context, WidgetRef ref, String currentDirectory) {
    final controller = TextEditingController(text: currentDirectory);
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('更改数据存储目录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('当前目录:'),
              const SizedBox(height: 4),
              Text(
                currentDirectory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '新目录路径',
                  hintText: '留空使用默认位置',
                  border: OutlineInputBorder(),
                ),
                enabled: !isChanging,
              ),
              const SizedBox(height: 8),
              Text(
                '注意：更改目录将自动迁移所有数据',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isChanging ? null : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: isChanging
                  ? null
                  : () async {
                      final newDirectory = controller.text.trim();

                      setDialogState(() => isChanging = true);

                      try {
                        // 使用默认目录
                        if (newDirectory.isEmpty) {
                          final appDocDir = await getApplicationDocumentsDirectory();
                          final defaultPath = '${appDocDir.path}${Platform.pathSeparator}vault_safe_data';

                          final storageService = ref.read(storageServiceProvider);
                          await storageService.changeDataDirectory(defaultPath);

                          if (context.mounted) {
                            await ref.read(settingsProvider.notifier).updateDataDirectory(defaultPath);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('存储目录已更改为默认位置')),
                            );
                          }
                          return;
                        }

                        // 验证目录路径
                        final dir = Directory(newDirectory);

                        // 如果目录不存在，尝试创建
                        if (!await dir.exists()) {
                          await dir.create(recursive: true);
                        }

                        // 测试写入权限
                        final testFile = File('${dir.path}${Platform.pathSeparator}.write_test');
                        await testFile.writeAsString('test');
                        await testFile.delete();

                        // 更改存储目录
                        final storageService = ref.read(storageServiceProvider);
                        await storageService.changeDataDirectory(newDirectory);

                        if (context.mounted) {
                          // 更新设置
                          await ref.read(settingsProvider.notifier).updateDataDirectory(newDirectory);

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('存储目录已更改，数据已迁移')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() => isChanging = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('更改失败: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('更改'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  void _showTimeoutDialog(BuildContext context, WidgetRef ref, Duration current) {
    showDialog(
      context: context,
      builder: (context) => _TimeoutDialog(current: current),
    );
  }

  String _formatTimeout(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} 秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} 分钟';
    } else {
      return '${duration.inHours} 小时';
    }
  }
}

/// 修改主密码对话框
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      // 更改密码 - changeMasterPassword 需要旧密码和新密码
      final currentPassword = _currentController.text;
      final newPassword = _newController.text;

      final success = await authService.changeMasterPassword(currentPassword, newPassword);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已成功更改'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前密码错误'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更改失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改主密码'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: '当前密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入当前密码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: '新密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入新密码';
                }
                if (value.length < 6) {
                  return '密码至少6位';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: '确认新密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认新密码';
                }
                if (value != _newController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确认'),
        ),
      ],
    );
  }
}

/// 自动锁定时间对话框
class _TimeoutDialog extends ConsumerWidget {
  final Duration current;

  const _TimeoutDialog({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeouts = [
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 5),
      const Duration(minutes: 15),
    ];

    String formatTimeout(Duration duration) {
      if (duration.inSeconds < 60) {
        return '${duration.inSeconds} 秒';
      } else if (duration.inMinutes < 60) {
        return '${duration.inMinutes} 分钟';
      } else {
        return '${duration.inHours} 小时';
      }
    }

    return AlertDialog(
      title: const Text('自动锁定时间'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: timeouts.map((timeout) {
          final isSelected = timeout == current;
          return ListTile(
            title: Text(formatTimeout(timeout)),
            trailing: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              ref.read(settingsProvider.notifier).updateAutoLockTimeout(timeout);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已设置为 ${formatTimeout(timeout)}')),
              );
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
