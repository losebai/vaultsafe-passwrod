import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/models/settings.dart';
import 'package:vaultsafe/features/settings/logs_screen.dart';
import 'package:vaultsafe/features/update/update_screen.dart';
import 'package:vaultsafe/shared/widgets/sync_settings_dialog.dart';
import 'package:vaultsafe/shared/widgets/sync_buttons.dart';
import 'package:vaultsafe/shared/helpers/backup_helper.dart';

/// 设置界面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: settingsAsync.when(
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
                      onTap: () => _showTimeoutDialog(
                          context, ref, settings.autoLockTimeout),
                    ),
                    _SettingsItem(
                      icon: Icons.verified_user_outlined,
                      title: '密码验证超时',
                      description: _formatTimeout(settings.passwordVerificationTimeout),
                      onTap: () => _showPasswordVerificationTimeoutDialog(
                          context, ref, settings.passwordVerificationTimeout),
                    ),
                    _SettingsItem(
                      icon: Icons.fingerprint,
                      title: '生物识别解锁',
                      description: settings.biometricEnabled ? '已启用' : '已禁用',
                      trailing: Switch(
                        value: settings.biometricEnabled,
                        onChanged: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateBiometricEnabled(value);
                        },
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
                  items: [
                    _SettingsItem(
                      icon: Icons.color_lens,
                      title: '主题颜色',
                      description: '自定义应用主题颜色',
                      onTap: () => _showThemeColorDialog(
                          context, ref, settings.themeColor),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (Platform.isAndroid) ...[
                  // 同步设置
                  _buildSyncCard(context, theme, settings, ref),
                ],

                const SizedBox(height: 24),

                // 数据存储 - 仅移动端显示
                if (Platform.isAndroid || Platform.isIOS)
                  _buildSettingsCard(
                    theme,
                    title: '数据存储',
                    icon: Icons.storage_outlined,
                    items: [
                      _SettingsItem(
                        icon: Icons.folder_outlined,
                        title: '数据存储目录',
                        description: settings.dataDirectory,
                        onTap: () => _showStorageDirectoryDialog(
                            context, ref, settings.dataDirectory),
                      ),
                      _SettingsItem(
                        icon: Icons.download,
                        title: '导出备份',
                        description: '下载加密备份文件',
                        onTap: () => _exportBackup(context, ref),
                      ),
                      _SettingsItem(
                        icon: Icons.upload,
                        title: '导入备份',
                        description: '从加密备份文件恢复',
                        onTap: () => _importBackup(context, ref),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // 系统设置
                _buildSettingsCard(
                  theme,
                  title: '系统',
                  icon: Icons.system_update,
                  items: [
                    // 桌面端显示自动更新开关
                    if (!Platform.isAndroid && !Platform.isIOS)
                      _SettingsItem(
                        icon: Icons.update,
                        title: '自动更新',
                        description:
                            settings.autoUpdateEnabled ? '每24小时自动检查' : '已禁用',
                        trailing: Switch(
                          value: settings.autoUpdateEnabled,
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateAutoUpdateEnabled(value);
                          },
                        ),
                      ),
                    _SettingsItem(
                      icon: Icons.system_update,
                      title: '检查更新',
                      description: '查看应用是否有新版本',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UpdateScreen(),
                          ),
                        );
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.bug_report_outlined,
                      title: '系统日志',
                      description: '查看应用程序运行日志',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LogsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 版本信息
                _VersionInfoCard(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          if (item.trailing != null)
                            item.trailing!
                          else if (item.onTap != null)
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

  String _formatTimeout(Duration timeout) {
    if (timeout.inMinutes >= 1) {
      return '${timeout.inMinutes} 分钟';
    }
    return '${timeout.inSeconds} 秒';
  }

  // 构建同步卡片（包含同步按钮）
  Widget _buildSyncCard(BuildContext context, ThemeData theme, AppSettings settings, WidgetRef ref) {
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sync_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '同步',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 启用同步开关
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '启用同步',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.syncEnabled ? '已启用' : '已禁用',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.syncEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateSyncEnabled(value);
                    if (value) {
                      _showSyncSettingsDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 56),
          // 同步配置
          InkWell(
            onTap: () => _showSyncSettingsDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '同步配置',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.syncConfig?.endpointUrl ?? '未配置',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 56),
          // 同步按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SyncButtons(settings: settings),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 显示修改密码弹窗
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  // 显示自动锁定时间选择弹窗
  void _showTimeoutDialog(
      BuildContext context, WidgetRef ref, Duration current) {
    showDialog(
      context: context,
      builder: (context) => _TimeoutDialog(current: current),
    );
  }

  // 显示密码验证超时时间选择弹窗
  void _showPasswordVerificationTimeoutDialog(
      BuildContext context, WidgetRef ref, Duration current) {
    showDialog(
      context: context,
      builder: (context) => _PasswordVerificationTimeoutDialog(current: current),
    );
  }

  // 显示同步设置弹窗
  void _showSyncSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SyncSettingsDialog(),
    );
  }

  // 显示存储目录设置弹窗
  void _showStorageDirectoryDialog(
      BuildContext context, WidgetRef ref, String currentDirectory) {
    showDialog(
      context: context,
      builder: (context) =>
          StorageDirectoryDialog(currentDirectory: currentDirectory),
    );
  }

  // 显示主题颜色选择弹窗
  void _showThemeColorDialog(
      BuildContext context, WidgetRef ref, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => _ThemeColorDialog(currentColor: currentColor),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    await BackupHelper.exportBackup(context, ref);
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    await BackupHelper.importBackup(context, ref);
  }
}

/// 修改密码弹窗
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
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
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
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
                      ref
                          .read(settingsProvider.notifier)
                          .updateAutoLockTimeout(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(_formatTimeout(timeout)),
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updateAutoLockTimeout(timeout);
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

/// 密码验证超时时间选择弹窗
class _PasswordVerificationTimeoutDialog extends ConsumerWidget {
  final Duration current;

  const _PasswordVerificationTimeoutDialog({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeouts = [
      const Duration(seconds: 10),
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '密码验证超时',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '查看、复制或编辑密码时需要验证主密码，验证成功后在此时间内无需重复验证',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                      ref
                          .read(settingsProvider.notifier)
                          .updatePasswordVerificationTimeout(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(_formatDuration(timeout)),
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updatePasswordVerificationTimeout(timeout);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration timeout) {
    if (timeout.inMinutes >= 1) {
      return '${timeout.inMinutes} 分钟';
    }
    return '${timeout.inSeconds} 秒';
  }
}

/// 同步设置弹窗
/// 存储目录设置弹窗
class StorageDirectoryDialog extends ConsumerStatefulWidget {
  final String currentDirectory;

  const StorageDirectoryDialog({super.key, required this.currentDirectory});

  @override
  ConsumerState<StorageDirectoryDialog> createState() =>
      _StorageDirectoryDialogState();
}

class _StorageDirectoryDialogState
    extends ConsumerState<StorageDirectoryDialog> {
  late TextEditingController _directoryController;
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _directoryController = TextEditingController(text: widget.currentDirectory);
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
                    Icons.folder,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '数据存储目录',
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

            const Text(
              '更改存储目录会将所有现有数据迁移到新位置。请确保选择的目录有足够的磁盘空间。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // 当前目录显示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '当前目录',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.currentDirectory,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 新目录输入
            TextFormField(
              controller: _directoryController,
              decoration: const InputDecoration(
                labelText: '新存储目录',
                hintText: 'C:\\Users\\YourName\\VaultSafeData',
                prefixIcon: Icon(Icons.folder_open),
                helperText: '请输入绝对路径，留空则使用默认目录',
              ),
              maxLines: 2,
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
                    onPressed: _isChanging ? null : _changeDirectory,
                    child: _isChanging
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更改目录'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDirectory() async {
    final newDirectory = _directoryController.text.trim();

    if (newDirectory.isEmpty) {
      // 使用默认目录
      final appDocDir = await getApplicationDocumentsDirectory();
      final defaultPath =
          '${appDocDir.path}${Platform.pathSeparator}vault_safe_data';

      setState(() => _isChanging = true);

      try {
        final storageService = ref.read(storageServiceProvider);
        await storageService.changeDataDirectory(defaultPath);

        if (!mounted) return;

        await ref
            .read(settingsProvider.notifier)
            .updateDataDirectory(defaultPath);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('存储目录已更改为默认位置')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更改失败: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isChanging = false);
        }
      }

      return;
    }

    // 验证目录路径
    final dir = Directory(newDirectory);

    setState(() => _isChanging = true);

    try {
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

      if (!mounted) return;

      // 更新设置
      await ref
          .read(settingsProvider.notifier)
          .updateDataDirectory(newDirectory);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('存储目录已更改，数据已迁移')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更改失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChanging = false);
      }
    }
  }

  @override
  void dispose() {
    _directoryController.dispose();
    super.dispose();
  }
}

/// 主题颜色选择对话框
class _ThemeColorDialog extends ConsumerWidget {
  final Color currentColor;

  const _ThemeColorDialog({required this.currentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableColors = SettingsNotifier.availableThemeColors;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '主题颜色',
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

            const Text(
              '选择您喜欢的主题颜色，应用界面将会即时更新。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),

            // 颜色网格
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: availableColors.length,
              itemBuilder: (context, index) {
                final color = availableColors[index];
                final isSelected = color == currentColor;

                return GestureDetector(
                  onTap: () async {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateThemeColor(color);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 当前颜色预览
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前颜色',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 版本信息卡片
class _VersionInfoCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionInfoCard> createState() => _VersionInfoCardState();
}

class _VersionInfoCardState extends ConsumerState<_VersionInfoCard> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 版本信息
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_packageInfo != null)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VaultSafe v${_packageInfo!.version}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '构建号: ${_packageInfo!.buildNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // 检查更新按钮
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UpdateScreen(),
                ),
              );
            },
            icon: const Icon(Icons.system_update, size: 18),
            label: const Text('检查更新'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置项数据模型
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
