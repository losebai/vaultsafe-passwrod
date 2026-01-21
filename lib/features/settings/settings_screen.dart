import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/settings/change_password_screen.dart';
import 'package:vaultsafe/features/settings/sync_settings_screen.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';

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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('同步配置'),
                subtitle: Text(settings.syncConfig?.endpointUrl ?? '未配置'),
                leading: const Icon(Icons.cloud_sync),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
                  );
                },
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

  void _showTimeoutDialog(BuildContext context, WidgetRef ref, Duration current) {
    final timeouts = [
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 5),
      const Duration(minutes: 15),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自动锁定时间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: timeouts.map((timeout) {
              return RadioListTile<Duration>(
                title: Text(_formatTimeout(timeout)),
                value: timeout,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateAutoLockTimeout(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
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
