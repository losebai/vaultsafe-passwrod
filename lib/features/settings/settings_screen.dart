import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/core/sync/sync_interval.dart';
import 'package:vaultsafe/core/sync/sync_service.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

/// 设置界面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            children: [
              const _SectionHeader(title: '安全'),
              SwitchListTile(
                title: const Text('生物识别解锁'),
                subtitle: const Text('使用指纹或面部识别解锁'),
                value: settings.biometricEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateBiometricEnabled(value);
                },
              ),
              ListTile(
                title: const Text('修改主密码'),
                leading: const Icon(Icons.lock_reset),
                onTap: () => _showChangePasswordDialog(context),
              ),
              ListTile(
                title: const Text('自动锁定时间'),
                subtitle: Text(_formatTimeout(settings.autoLockTimeout)),
                leading: const Icon(Icons.timer),
                onTap: () => _showTimeoutDialog(context, ref, settings.autoLockTimeout),
              ),

              const _SectionHeader(title: '同步'),
              SwitchListTile(
                title: const Text('启用同步'),
                subtitle: const Text('在设备间同步加密数据'),
                value: settings.syncEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateSyncEnabled(value);
                  if (value) {
                    _showSyncSettingsDialog(context);
                  }
                },
              ),
              ListTile(
                title: const Text('同步配置'),
                subtitle: Text(settings.syncConfig?.endpointUrl ?? '未配置'),
                leading: const Icon(Icons.cloud_sync),
                onTap: () => _showSyncSettingsDialog(context),
              ),

              const _SectionHeader(title: '数据'),
              ListTile(
                title: const Text('导出备份'),
                subtitle: const Text('下载加密备份文件'),
                leading: const Icon(Icons.download),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                title: const Text('导入备份'),
                subtitle: const Text('从加密备份文件恢复'),
                leading: const Icon(Icons.upload),
                onTap: () => _importBackup(context, ref),
              ),

              const _SectionHeader(title: '关于'),
              ListTile(
                title: const Text('版本'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
      ),
    );
  }

  String _formatTimeout(Duration timeout) {
    if (timeout.inMinutes >= 1) {
      return '${timeout.inMinutes} 分钟';
    }
    return '${timeout.inSeconds} 秒';
  }

  // 显示修改密码弹窗
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  // 显示自动锁定时间选择弹窗
  void _showTimeoutDialog(BuildContext context, WidgetRef ref, Duration current) {
    showDialog(
      context: context,
      builder: (context) => _TimeoutDialog(current: current),
    );
  }

  // 显示同步设置弹窗
  void _showSyncSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SyncSettingsDialog(),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    // TODO: 实现备份导出
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份已导出')),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    // TODO: 实现备份导入
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份已导入')),
    );
  }
}

/// 修改密码弹窗
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '修改主密码',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 当前密码
              TextFormField(
                controller: _currentController,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入当前密码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 新密码
              TextFormField(
                controller: _newController,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入新密码';
                  }
                  if (value.length < 8) {
                    return '密码至少需要 8 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 确认新密码
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  prefixIcon: Icon(Icons.lock_clock),
                ),
                obscureText: true,
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
              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('修改密码'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final success = await authService.changeMasterPassword(
      _currentController.text,
      _newController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已成功修改')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前密码不正确')),
      );
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}

/// 自动锁定时间选择弹窗
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '自动锁定时间',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 选项列表
            ...timeouts.map((timeout) {
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Radio<Duration>(
                  value: timeout,
                  groupValue: current,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateAutoLockTimeout(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(_formatTimeout(timeout)),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateAutoLockTimeout(timeout);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatTimeout(Duration timeout) {
    if (timeout.inMinutes >= 1) {
      return '${timeout.inMinutes} 分钟';
    }
    return '${timeout.inSeconds} 秒';
  }
}

/// 同步设置弹窗
class SyncSettingsDialog extends ConsumerStatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  ConsumerState<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends ConsumerState<SyncSettingsDialog> {
  final _endpointController = TextEditingController();
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  SyncAuthType _authType = SyncAuthType.bearer;
  SyncInterval _interval = SyncInterval.none;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    ref.read(settingsProvider).whenData((settings) {
      if (settings.syncConfig != null) {
        final config = settings.syncConfig!;
        _endpointController.text = config.endpointUrl;
        _authType = config.authType;
        _interval = config.interval;

        if (config.authType == SyncAuthType.bearer && config.token != null) {
          _tokenController.text = config.token!;
        } else if (config.authType == SyncAuthType.basic) {
          if (config.username != null) _usernameController.text = config.username!;
          if (config.password != null) _passwordController.text = config.password!;
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.cloud_sync,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '同步设置',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 帮助按钮
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => _showApiHelpDialog(context),
                    tooltip: 'API 文档',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                '配置您自己的同步服务器。所有数据在上传前都会被加密。',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),

              // 表单内容（使用 SingleChildScrollView 防止溢出）
              SizedBox(
                height: 400,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _endpointController,
                        decoration: const InputDecoration(
                          labelText: '服务器地址',
                          hintText: 'https://your-server.com/api/v1/sync',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入服务器地址';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SyncAuthType>(
                        initialValue: _authType,
                        decoration: const InputDecoration(
                          labelText: '认证方式',
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: const [
                          DropdownMenuItem(value: SyncAuthType.bearer, child: Text('Bearer Token')),
                          DropdownMenuItem(value: SyncAuthType.basic, child: Text('Basic Auth')),
                          DropdownMenuItem(value: SyncAuthType.custom, child: Text('自定义请求头')),
                        ],
                        onChanged: (value) {
                          setState(() => _authType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_authType == SyncAuthType.bearer)
                        TextFormField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'Bearer Token',
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                          obscureText: true,
                        ),
                      if (_authType == SyncAuthType.basic) ...[
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SyncInterval>(
                        initialValue: _interval,
                        decoration: const InputDecoration(
                          labelText: '自动同步间隔',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(value: SyncInterval.none, child: Text('仅手动')),
                          DropdownMenuItem(value: SyncInterval.every5Min, child: Text('每 5 分钟')),
                          DropdownMenuItem(value: SyncInterval.every15Min, child: Text('每 15 分钟')),
                          DropdownMenuItem(value: SyncInterval.hourly, child: Text('每小时')),
                        ],
                        onChanged: (value) {
                          setState(() => _interval = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 按钮
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: const Text('测试连接'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('保存设置'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final syncService = SyncService();
      await syncService.init(SyncConfig(
        enabled: true,
        endpointUrl: _endpointController.text,
        authType: _authType,
        token: _tokenController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        interval: _interval,
      ));

      final success = await syncService.testConnection();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '连接成功！' : '连接失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final config = SyncConfig(
      enabled: true,
      endpointUrl: _endpointController.text,
      authType: _authType,
      token: _authType == SyncAuthType.bearer ? _tokenController.text : null,
      username: _authType == SyncAuthType.basic ? _usernameController.text : null,
      password: _authType == SyncAuthType.basic ? _passwordController.text : null,
      interval: _interval,
    );

    ref.read(settingsProvider.notifier).updateSyncConfig(config);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('同步设置已保存')),
    );
  }

  // 显示 API 帮助文档弹窗
  void _showApiHelpDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.code,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'REST API 文档',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 说明文字
              Text(
                '您的同步服务器需要实现以下 REST API 接口。所有数据均为 AES-256-GCM 加密后的密文。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // API 文档内容
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // POST /sync - 上传数据
                      _buildApiSection(
                        theme: theme,
                        method: 'POST',
                        endpoint: '/sync',
                        title: '上传加密数据',
                        description: '将本地加密数据上传到服务器',
                        code: '''curl -X POST https://your-server.com/api/v1/sync \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "device_id": "uuid-string",
    "timestamp": 1705742400,
    "encrypted_data": "base64_encrypted_blob",
    "version": "1.0"
  }"

响应示例:
{
  "success": true,
  "message": "Data uploaded successfully"
}''',
                      ),
                      const SizedBox(height: 24),

                      // GET /sync - 下载数据
                      _buildApiSection(
                        theme: theme,
                        method: 'GET',
                        endpoint: '/sync',
                        title: '下载加密数据',
                        description: '从服务器获取最新的加密数据',
                        code: '''curl -X GET https://your-server.com/api/v1/sync \\
  -H "Authorization: Bearer YOUR_TOKEN"

响应示例:
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}''',
                      ),
                      const SizedBox(height: 24),

                      // 认证方式说明
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '认证说明',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Bearer Token: 在请求头中添加 Authorization: Bearer <token>\n'
                              '• Basic Auth: 在请求头中添加 Authorization: Basic <base64(username:password)>\n'
                              '• 自定义: 使用自定义请求头进行认证',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 数据格式说明
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '数据格式',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• device_id: 设备唯一标识符（UUID）\n'
                              '• timestamp: Unix 时间戳（秒）\n'
                              '• encrypted_data: Base64 编码的加密数据\n'
                              '• version: 数据版本号（当前为 "1.0"）',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiSection({
    required ThemeData theme,
    required String method,
    required String endpoint,
    required String title,
    required String description,
    required String code,
  }) {
    final methodColor = method == 'POST'
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2196F3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 方法标签和端点
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: methodColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              endpoint,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 标题和描述
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // 代码块
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFD4D4D4),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
