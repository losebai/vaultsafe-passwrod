import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';

/// 设置界面 - 桌面端和移动端通用
class SettingsLayout extends ConsumerWidget {
  const SettingsLayout({super.key});

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
                  SettingsItem(
                    icon: Icons.lock_reset,
                    title: '修改主密码',
                    description: '更改您的访问密码',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  SettingsItem(
                    icon: Icons.timer_outlined,
                    title: '自动锁定',
                    description: _formatTimeout(settings.autoLockTimeout),
                    onTap: () => _showTimeoutDialog(
                        context, ref, settings.autoLockTimeout),
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
                  SettingsItem(
                    icon: Icons.folder_outlined,
                    title: '数据存储目录',
                    description: settings.dataDirectory,
                    onTap: () => _showDataDirectoryDialog(
                        context, ref, settings.dataDirectory),
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
                  SettingsItem(
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

  void _showDataDirectoryDialog(
      BuildContext context, WidgetRef ref, String currentDirectory) {
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
                          final appDocDir =
                              await getApplicationDocumentsDirectory();
                          final defaultPath =
                              '${appDocDir.path}${Platform.pathSeparator}vault_safe_data';

                          final storageService =
                              ref.read(storageServiceProvider);
                          await storageService.changeDataDirectory(defaultPath);

                          if (context.mounted) {
                            await ref
                                .read(settingsProvider.notifier)
                                .updateDataDirectory(defaultPath);
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
                        final testFile = File(
                            '${dir.path}${Platform.pathSeparator}.write_test');
                        await testFile.writeAsString('test');
                        await testFile.delete();

                        // 更改存储目录
                        final storageService = ref.read(storageServiceProvider);
                        await storageService.changeDataDirectory(newDirectory);

                        if (context.mounted) {
                          // 更新设置
                          await ref
                              .read(settingsProvider.notifier)
                              .updateDataDirectory(newDirectory);

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
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showTimeoutDialog(
      BuildContext context, WidgetRef ref, Duration current) {
    showDialog(
      context: context,
      builder: (context) => TimeoutDialog(current: current),
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

/// 修改主密码对话框
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog();

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

      final success =
          await authService.changeMasterPassword(currentPassword, newPassword);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('密码已成功更改'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('当前密码错误'), backgroundColor: Colors.red),
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
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
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
                  icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility),
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
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
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
class TimeoutDialog extends ConsumerWidget {
  final Duration current;

  const TimeoutDialog({required this.current});

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
              ref
                  .read(settingsProvider.notifier)
                  .updateAutoLockTimeout(timeout);
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
