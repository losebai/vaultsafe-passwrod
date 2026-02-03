import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/widgets/apiHelpDialog.dart';
import 'package:vaultsafe/shared/widgets/sync_settings_dialog.dart';
import 'package:vaultsafe/shared/widgets/settings_card.dart';
import 'package:vaultsafe/shared/widgets/master_password_dialog.dart';
import 'package:vaultsafe/shared/helpers/backup_helper.dart';
import 'package:vaultsafe/core/sync/sync_service.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/settings.dart';

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
                      _SyncButtons(settings: settings),
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
        // TODO: 实现更改目录逻辑
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

/// 同步按钮组
class _SyncButtons extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _SyncButtons({required this.settings});

  @override
  ConsumerState<_SyncButtons> createState() => _SyncButtonsState();
}

class _SyncButtonsState extends ConsumerState<_SyncButtons> {
  bool _isSyncing = false;
  bool _isUploading = false;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConfig = widget.settings.syncConfig != null;

    return Column(
      children: [
        Row(
          children: [ 
            Icon(
              Icons.cloud_upload_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '上传到服务器',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: (hasConfig && !_isSyncing) ? _uploadData : null,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: const Text('上传'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '从服务器下载',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: (hasConfig && !_isSyncing) ? _downloadData : null,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: const Text('下载'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadData() async {
    if (!mounted) return;

    // 首先询问是否使用自定义密码
    final useCustomPassword = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加密方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择加密方式：'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('使用当前主密码'),
              subtitle: const Text('使用您当前登录的主密码加密（推荐）'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.password, color: Colors.blue),
              title: const Text('使用自定义密码'),
              subtitle: const Text('使用不同的密码加密，可用于多个密码库'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (useCustomPassword == null || !mounted) return;

    // 如果使用自定义密码，弹出输入对话框
    Uint8List? masterKey;
    String? customPasswordHint;

    if (useCustomPassword == true) {
      final customPassword = await showMasterPasswordDialog(
        context,
        title: '输入加密密码',
        hintText: '此密码将用于加密备份数据',
        onVerify: (password) {
          // 只需要验证密码不为空即可
          return password.isNotEmpty;
        },
      );

      if (customPassword == null || !mounted) return;

      // 使用自定义密码派生密钥
      const storage = FlutterSecureStorage();
      final salt = await storage.read(key: 'master_salt');
      if (salt == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取加密盐，请先设置主密码'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final saltBytes = Uint8List.fromList(
        List.generate(salt.length ~/ 2, (i) => int.parse(salt.substring(i * 2, i * 2 + 2), radix: 16)),
      );
      masterKey = EncryptionService.deriveKey(customPassword, saltBytes);
      customPasswordHint = ' (使用自定义密码加密)';
    } else {
      // 使用当前主密码
      final authService = ref.read(authServiceProvider);
      if (!authService.isUnlocked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请先解锁 VaultSafe'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      masterKey = authService.masterKey;
      if (masterKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取加密密钥'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // 确认上传
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认上传'),
        content: Text('上传将覆盖服务器上的数据${useCustomPassword ? "，使用自定义密码加密" : ""}，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('上传'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSyncing = true;
      _isUploading = true;
    });

    try {
      // 导出数据
      final storageService = ref.read(storageServiceProvider);
      final data = await storageService.exportData();
      final jsonString = jsonEncode(data);

      // 加密数据
      final encrypted = EncryptionService.encrypt(jsonString, masterKey!);

      // 创建备份数据结构（与导出格式相同）
      final backupData = {
        'version': '1.0',
        'format': 'vaultsafe-encrypted',
        'encrypted': true,
        'data': encrypted.toJson(),
        'checksum': _calculateChecksum(jsonString),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // 上传到同步服务器
      final syncConfig = widget.settings.syncConfig!;
      final syncService = SyncService();
      await syncService.init(syncConfig);

      final success = await syncService.uploadData(jsonEncode(backupData));

      if (!mounted) return;

      if (success) {
        // 更新最后同步时间
        await ref.read(settingsProvider.notifier).updateSyncConfig(
              syncConfig.copyWith(lastSyncedAt: DateTime.now()),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('数据上传成功$customPasswordHint'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('上传失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _downloadData() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认下载'),
        content: const Text('下载将覆盖本地数据，建议先上传备份。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('下载'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSyncing = true;
      _isDownloading = true;
    });

    try {
      // 1. 从同步服务器下载
      final syncConfig = widget.settings.syncConfig!;
      final syncService = SyncService();
      await syncService.init(syncConfig);

      SyncData? syncData;
      try {
        syncData = await syncService.downloadData();
      } catch (e) {
        throw Exception('服务器连接失败: ${e.toString()}');
      }

      if (syncData == null) {
        throw Exception('服务器返回空数据，可能没有上传过数据');
      }

      // 2. 解析备份数据
      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(syncData.encryptedData) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('数据格式错误，无法解析: ${e.toString()}');
      }

      // 3. 验证备份格式
      final version = backupData['version'] as String?;
      if (version != '1.0') {
        throw Exception('不支持的备份版本: $version');
      }

      final isEncrypted = backupData['encrypted'] as bool? ?? false;
      if (!isEncrypted) {
        throw Exception('备份文件未加密');
      }

      if (!backupData.containsKey('data')) {
        throw Exception('备份数据缺少加密内容');
      }

      final encryptedData = backupData['data'] as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(encryptedData);

      // 4. 尝试解密数据
      String decryptedJson;
      bool useCustomPassword = false;

      // 首先尝试使用当前主密码
      final authService = ref.read(authServiceProvider);
      Uint8List? masterKey = authService.masterKey;

      if (masterKey != null) {
        try {
          decryptedJson = EncryptionService.decrypt(encrypted, masterKey);
        } catch (e) {
          // 当前主密码解密失败，尝试让用户输入自定义密码
          if (!mounted) {
            setState(() {
              _isSyncing = false;
              _isDownloading = false;
            });
            return;
          }

          final customDecrypted = await _decryptWithCustomPassword(encrypted, backupData);
          if (customDecrypted == null || !mounted) {
            setState(() {
              _isSyncing = false;
              _isDownloading = false;
            });
            return;
          }
          decryptedJson = customDecrypted;
          useCustomPassword = true;
        }
      } else {
        // 没有当前主密钥，直接要求输入
        if (!mounted) {
          setState(() {
            _isSyncing = false;
            _isDownloading = false;
          });
          return;
        }

        final customDecrypted = await _decryptWithCustomPassword(encrypted, backupData);
        if (customDecrypted == null || !mounted) {
          setState(() {
            _isSyncing = false;
            _isDownloading = false;
          });
          return;
        }
        decryptedJson = customDecrypted;
        useCustomPassword = true;
      }

      // 5. 验证校验和
      final storedChecksum = backupData['checksum'] as String?;
      final calculatedChecksum = _calculateChecksum(decryptedJson);
      if (storedChecksum != null && storedChecksum != calculatedChecksum) {
        throw Exception('数据校验和不匹配，可能已损坏');
      }

      // 6. 解析并导入数据
      final data = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final storageService = ref.read(storageServiceProvider);

      try {
        await storageService.importData(data);
      } catch (e) {
        throw Exception('导入数据失败: ${e.toString()}');
      }

      if (!mounted) return;

      // 7. 刷新界面
      await ref.read(passwordEntriesProvider.notifier).loadEntries();
      await ref.read(passwordGroupsProvider.notifier).loadGroups();

      // 8. 更新最后同步时间
      await ref.read(settingsProvider.notifier).updateSyncConfig(
            syncConfig.copyWith(lastSyncedAt: DateTime.now()),
          );

      if (mounted) {
        final passwordCount = (data['passwords'] as List?)?.length ?? 0;
        final groupCount = (data['groups'] as List?)?.length ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载成功: $passwordCount 个密码, $groupCount 个分组${useCustomPassword ? " (使用自定义密码解密)" : ""}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isDownloading = false;
        });
      }
    }
  }

  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 使用自定义密码解密数据
  Future<String?> _decryptWithCustomPassword(
    EncryptedData encrypted,
    Map<String, dynamic> backupData,
  ) async {
    const storage = FlutterSecureStorage();

    // 读取salt
    final salt = await storage.read(key: 'master_salt');
    if (salt == null) return null;

    final saltBytes = Uint8List.fromList(
      List.generate(salt.length ~/ 2, (i) => int.parse(salt.substring(i * 2, i * 2 + 2), radix: 16)),
    );

    // 显示对话框让用户输入密码
    final customPassword = await showMasterPasswordDialog(
      context,
      title: '输入解密密码',
      hintText: '此备份使用不同的主密码加密',
      onVerify: (password) {
        try {
          final customKey = EncryptionService.deriveKey(password, saltBytes);
          final testDecrypted = EncryptionService.decrypt(encrypted, customKey);

          // 验证校验和
          final storedChecksum = backupData['checksum'] as String?;
          if (storedChecksum != null) {
            final calculatedChecksum = _calculateChecksum(testDecrypted);
            return storedChecksum == calculatedChecksum;
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    );

    if (customPassword == null) return null;

    // 使用自定义密码解密
    final customKey = EncryptionService.deriveKey(customPassword, saltBytes);
    return EncryptionService.decrypt(encrypted, customKey);
  }
}
