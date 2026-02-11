import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/core/sync/sync_interval.dart';
import 'package:vaultsafe/core/sync/sync_service.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';

/// 同步设置界面 - 配置第三方同步
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '配置您自己的同步服务器。所有数据在上传前都会被加密。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                border: OutlineInputBorder(),
                hintText: 'https://your-server.com/api/v1/sync',
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
                border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            if (_authType == SyncAuthType.basic) ...[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<SyncInterval>(
              initialValue: _interval,
              decoration: const InputDecoration(
                labelText: '自动同步间隔',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('保存设置'),
            ),
          ],
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

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
