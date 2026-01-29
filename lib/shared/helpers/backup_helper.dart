import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vaultsafe/core/backup/backup_service.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';

/// 备份功能助手 - 可在多个地方复用
class BackupHelper {
  /// 导出备份
  static Future<void> exportBackup(
    BuildContext context,
    WidgetRef ref
  ) async {
    // 检查是否已解锁
    final authService = ref.read(authServiceProvider);
    if (!authService.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先解锁 VaultSafe')),
      );
      return;
    }

    // 获取主密钥
    final masterKey = authService.masterKey;
    if (masterKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取加密密钥')),
      );
      return;
    }

    // 显示加载对话框
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导出备份...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final storageService = ref.read(storageServiceProvider);
      final backupService = BackupService(storageService);

      // 导出加密备份
      final backupFile = await backupService.exportEncryptedBackup(masterKey);

      // 清理旧备份（保留最近 5 个）
      await backupService.cleanupOldBackups();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框

      // 显示成功对话框
      showDialog(
        context: context,
        builder: (context) => _ExportSuccessDialog(backupFile: backupFile),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 导入备份
  static Future<void> importBackup(
    BuildContext context,
    WidgetRef ref
  ) async {
    // 检查是否已解锁
    final authService = ref.read(authServiceProvider);
    if (!authService.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先解锁 VaultSafe')),
      );
      return;
    }

    // 使用文件选择器选择备份文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择 VaultSafe 备份文件',
    );

    if (result == null || result.files.isEmpty) {
      return; // 用户取消选择
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法读取选择的文件')),
      );
      return;
    }

    final backupFile = File(filePath);

    // 显示确认对话框
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ImportConfirmDialog(backupFile: backupFile),
    );

    if (confirmed != true) {
      return; // 用户取消导入
    }

    // 显示加载对话框
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入备份...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 获取主密钥
      final masterKey = authService.masterKey;
      if (masterKey == null) {
        throw Exception('无法获取加密密钥');
      }

      final storageService = ref.read(storageServiceProvider);
      final backupService = BackupService(storageService);

      // 导入备份
      final importResult =
          await backupService.importEncryptedBackup(backupFile, masterKey);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框

      if (importResult.success) {
        // 刷新密码列表
        await ref.read(passwordEntriesProvider.notifier).loadEntries();
        await ref.read(passwordGroupsProvider.notifier).loadGroups();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.toString()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.error ?? '导入失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 导出成功对话框
class _ExportSuccessDialog extends ConsumerWidget {
  final File backupFile;

  const _ExportSuccessDialog({required this.backupFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成功图标
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '备份导出成功！',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '您的加密备份已保存到：',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                backupFile.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '🔒 此备份使用您的主密码加密，请妥善保管备份文件和主密码。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 导入确认对话框
class _ImportConfirmDialog extends ConsumerStatefulWidget {
  final File backupFile;

  const _ImportConfirmDialog({required this.backupFile});

  @override
  ConsumerState<_ImportConfirmDialog> createState() =>
      _ImportConfirmDialogState();
}

class _ImportConfirmDialogState extends ConsumerState<_ImportConfirmDialog> {
  bool _isLoading = true;
  BackupInfo? _backupInfo;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final storageService = ref.read(storageServiceProvider);
    final backupService = BackupService(storageService);
    final info = await backupService.getBackupInfo(widget.backupFile);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _backupInfo = info;
      });
    }
  }

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
                    Icons.upload_file,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '确认导入备份',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 警告信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '导入备份将覆盖现有数据，建议先导出当前数据作为备份。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_backupInfo == null)
              Text(
                '无法读取备份文件信息',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    theme,
                    Icons.verified,
                    '版本',
                    _backupInfo!.version,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    _backupInfo!.isEncrypted ? Icons.lock : Icons.lock_open,
                    '加密状态',
                    _backupInfo!.isEncrypted ? '已加密' : '未加密',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    Icons.schedule,
                    '导出时间',
                    _backupInfo!.formattedExportDate ?? '未知',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    Icons.storage,
                    '文件大小',
                    _backupInfo!.formattedFileSize,
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _backupInfo != null
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('确认导入'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
