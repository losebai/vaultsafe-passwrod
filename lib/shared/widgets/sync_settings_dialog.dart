import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/core/sync/sync_interval.dart';
import 'package:vaultsafe/core/sync/sync_service.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/widgets/apiHelpDialog.dart';

/// 同步设置对话框 - 可在多个地方复用
class SyncSettingsDialog extends ConsumerStatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  ConsumerState<SyncSettingsDialog> createState() => SyncSettingsDialogState();
}

class SyncSettingsDialogState extends ConsumerState<SyncSettingsDialog> {
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
    // 成功加载时候回调
    ref.read(settingsProvider).whenData((settings) {
      if (settings.syncConfig != null) {
        final config = settings.syncConfig!;
        _endpointController.text = config.endpointUrl;
        _authType = config.authType;
        _interval = config.interval;

        if (config.authType == SyncAuthType.bearer && config.token != null) {
          _tokenController.text = config.token!;
        } else if (config.authType == SyncAuthType.basic) {
          if (config.username != null) {
            _usernameController.text = config.username!;
          }
          if (config.password != null) {
            _passwordController.text = config.password!;
          }
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
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
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
                    onPressed: () => showApiHelpDialog(context),
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
                          DropdownMenuItem(
                              value: SyncAuthType.bearer,
                              child: Text('Bearer Token')),
                          DropdownMenuItem(
                              value: SyncAuthType.basic,
                              child: Text('Basic Auth')),
                          DropdownMenuItem(
                              value: SyncAuthType.custom,
                              child: Text('自定义请求头')),
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
                          DropdownMenuItem(
                              value: SyncInterval.none, child: Text('仅手动')),
                          DropdownMenuItem(
                              value: SyncInterval.every5Min,
                              child: Text('每 5 分钟')),
                          DropdownMenuItem(
                              value: SyncInterval.every15Min,
                              child: Text('每 15 分钟')),
                          DropdownMenuItem(
                              value: SyncInterval.hourly, child: Text('每小时')),
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
      username:
          _authType == SyncAuthType.basic ? _usernameController.text : null,
      password:
          _authType == SyncAuthType.basic ? _passwordController.text : null,
      interval: _interval,
    );

    ref.read(settingsProvider.notifier).updateSyncConfig(config);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('同步设置已保存')),
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
