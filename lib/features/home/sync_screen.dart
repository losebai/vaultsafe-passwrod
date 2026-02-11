import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/widgets/apiHelpDialog.dart';
import 'package:vaultsafe/shared/widgets/sync_settings_dialog.dart';
import 'package:vaultsafe/shared/widgets/settings_card.dart';
import 'package:vaultsafe/shared/widgets/sync_buttons.dart';
import 'package:vaultsafe/shared/helpers/backup_helper.dart';

/// 同步界面 - 桌面端和移动端通用
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return settingsAsync.when(
      data: (settings) {
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
                    onPressed: () => showApiHelpDialog(context),
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

              // 同步配置卡片
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
                                  settings.syncConfig?.endpointUrl ?? '未配置同步服务器',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const SyncSettingsDialog(),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('配置'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SyncButtons(settings: settings),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 导入导出
              SettingsCard(
                theme: theme,
                title: '导入导出',
                icon: Icons.swap_vert_outlined,
                items: [
                  SettingsItem(
                    icon: Icons.download_outlined,
                    title: '导出备份',
                    description: '下载加密备份文件',
                    onTap: () => BackupHelper.exportBackup(context, ref),
                  ),
                  SettingsItem(
                    icon: Icons.upload_outlined,
                    title: '导入备份',
                    description: '从备份文件恢复数据',
                    onTap: () => BackupHelper.importBackup(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 桌面端显示存储目录设置
              if (!Platform.isAndroid && !Platform.isIOS)
                SettingsCard(
                  theme: theme,
                  title: '数据存储',
                  icon: Icons.storage_outlined,
                  items: [
                    SettingsItem(
                      icon: Icons.folder_outlined,
                      title: '数据存储目录',
                      description: settings.dataDirectory,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _StorageDirectoryDialog(
                            currentDirectory: settings.dataDirectory,
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('错误: $err')),
    );
  }
}

/// 存储目录设置对话框
class _StorageDirectoryDialog extends ConsumerStatefulWidget {
  final String currentDirectory;

  const _StorageDirectoryDialog({super.key, required this.currentDirectory});

  @override
  ConsumerState<_StorageDirectoryDialog> createState() =>
      _StorageDirectoryDialogState();
}

class _StorageDirectoryDialogState extends ConsumerState<_StorageDirectoryDialog> {
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
            TextField(
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
        if (mounted) {
          await ref
              .read(settingsProvider.notifier)
              .updateDataDirectory(defaultPath);

          if (!context.mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('存储目录已更改为默认位置')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isChanging = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更改失败: $e')),
          );
        }
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

      // TODO: 实现更改目录逻辑
      if (mounted) {
        await ref
            .read(settingsProvider.notifier)
            .updateDataDirectory(newDirectory);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('存储目录已更改，数据已迁移')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChanging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更改失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
