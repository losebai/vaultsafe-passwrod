import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_interval.dart';

/// 同步界面 - 桌面端和移动端通用
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
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
      builder: (context) => const SyncConfigDialog(),
    );
  }

  // 同步帮助对话框
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
              const Text('上传数据 (POST):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('下载数据 (GET):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
                          color: const Color.fromARGB(255, 0, 72, 120)
                              .withValues(alpha: 0.1),
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
                        _lastSyncTime != null
                            ? Icons.cloud_done
                            : Icons.cloud_off,
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
            theme: theme,
            title: '导入导出',
            icon: Icons.swap_vert_outlined,
            items: [
              SettingsItem(
                icon: Icons.download_outlined,
                title: '导出备份',
                description: '下载加密备份文件',
                onTap: () {
                  _showExportDialog();
                },
              ),
              SettingsItem(
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

  Widget _buildSettingsCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<SettingsItem> items,
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
                    color: const Color.fromARGB(255, 0, 72, 120)
                        .withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
class SyncConfigDialog extends StatefulWidget {
  const SyncConfigDialog();

  @override
  State<SyncConfigDialog> createState() => SyncConfigDialogState();
}

class SyncConfigDialogState extends State<SyncConfigDialog> {
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
        if (_usernameController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty) {
          final credentials = base64.encode(
            utf8.encode(
                '${_usernameController.text}:${_passwordController.text}'),
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
                onChanged: _isEnabled
                    ? (value) {
                        setState(() => _authType = value!);
                      }
                    : null,
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
                onChanged: _isEnabled
                    ? (value) {
                        setState(() => _interval = value!);
                      }
                    : null,
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

/// 设置项数据模型
class SettingsItem {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.trailing,
  });
}
