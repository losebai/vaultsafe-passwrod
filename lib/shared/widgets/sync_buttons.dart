import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/widgets/master_password_dialog.dart';
import 'package:vaultsafe/core/sync/sync_service.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/settings.dart';

/// 同步按钮组 - 可在设置和同步界面中复用
class SyncButtons extends ConsumerStatefulWidget {
  final AppSettings settings;

  const SyncButtons({super.key, required this.settings});

  @override
  ConsumerState<SyncButtons> createState() => SyncButtonsState();
}

class SyncButtonsState extends ConsumerState<SyncButtons> {
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
    String? saltHex; // 保存salt用于上传

    if (useCustomPassword == true) {
      final customPassword = await showMasterPasswordDialog(
        context,
        title: '输入加密密码',
        hintText: '此密码将用于加密备份数据',
        onVerify: (password) async {
          // 只需要验证密码不为空即可
          return password.isNotEmpty;
        },
      );

      if (customPassword == null || !mounted) return;

      // 使用自定义密码派生密钥
      const storage = FlutterSecureStorage();
      saltHex = await storage.read(key: 'master_salt');
      if (saltHex == null) {
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
        List.generate(saltHex!.length ~/ 2, (i) => int.parse(saltHex!.substring(i * 2, i * 2 + 2), radix: 16)),
      );
      masterKey = await EncryptionService.deriveKeyAsync(customPassword, saltBytes);
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

      // 读取salt用于上传
      const storage = FlutterSecureStorage();
      saltHex = await storage.read(key: 'master_salt');
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
        'salt': saltHex, // 包含salt用于跨设备解密
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
            const SnackBar(
              content: Text('数据上传成功'),
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

      // 获取备份中的 salt（用于跨设备解密）
      final backupSalt = backupData['salt'] as String?;

      final encryptedData = backupData['data'] as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(encryptedData);

      // 4. 尝试解密数据
      String decryptedJson;
      Uint8List? backupKey; // 备份时使用的密钥（用于重新加密）
      bool useCustomPassword = false;

      // 如果备份中有 salt，使用备份的 salt（跨设备同步）
      if (backupSalt != null) {
        final decryptedWithKey = await _decryptWithBackupSaltAndKey(encrypted, backupSalt, backupData);
        if (decryptedWithKey == null || !mounted) {
          setState(() {
            _isSyncing = false;
            _isDownloading = false;
          });
          return;
        }
        decryptedJson = decryptedWithKey.json;
        backupKey = decryptedWithKey.backupKey;
      } else {
        // 旧版本备份没有 salt，使用本地方式
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
        // 获取本地主密钥
        final authService = ref.read(authServiceProvider);
        final localMasterKey = authService.masterKey;

        if (localMasterKey == null) {
          throw Exception('请先设置本地主密码');
        }

        // 如果有备份密钥（与本地密钥不同），需要重新加密所有密码
        if (backupKey != null) {
          // 检查密钥是否相同
          bool keysAreEqual = backupKey.length == localMasterKey.length;
          if (keysAreEqual) {
            for (int i = 0; i < backupKey.length; i++) {
              if (backupKey[i] != localMasterKey[i]) {
                keysAreEqual = false;
                break;
              }
            }
          }

          if (!keysAreEqual) {
            // 密钥不同，需要重新加密
            log.i('密钥不同，将重新加密所有密码条目', source: 'SyncButtons');

            // 显示进度对话框
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('正在处理数据'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('正在重新加密 ${data['passwords']?.length ?? 0} 个密码条目...\n这可能需要几分钟时间'),
                  ],
                ),
              ),
            );

            try {
              await storageService.importDataWithReEncryption(
                data,
                backupKey,
                localMasterKey,
                onProgress: (processed, total) {
                  // 可以在这里更新进度
                  log.d('重新加密进度: $processed/$total', source: 'SyncButtons');
                },
              );

              // 关闭进度对话框
              if (mounted) Navigator.of(context).pop();
            } catch (e) {
              // 关闭进度对话框
              if (mounted) Navigator.of(context).pop();
              rethrow;
            }
          } else {
            // 密钥相同，直接导入
            await storageService.importData(data);
          }
        } else {
          // 没有备份密钥，直接导入
          await storageService.importData(data);
        }
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
      onVerify: (password) async {
        try {
          final customKey = await EncryptionService.deriveKeyAsync(password, saltBytes);
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
    final customKey = await EncryptionService.deriveKeyAsync(customPassword, saltBytes);
    return EncryptionService.decrypt(encrypted, customKey);
  }

  /// 使用备份中的 salt 解密数据并返回密钥
  /// 返回解密后的 JSON 字符串和备份密钥（用于重新加密）
  Future<_DecryptedDataWithKey?> _decryptWithBackupSaltAndKey(
    EncryptedData encrypted,
    String backupSalt,
    Map<String, dynamic> backupData,
  ) async {
    // 将备份的 salt 转换为字节数组
    final saltBytes = Uint8List.fromList(
      List.generate(backupSalt.length ~/ 2, (i) => int.parse(backupSalt.substring(i * 2, i * 2 + 2), radix: 16)),
    );

    // 显示对话框让用户输入主密码
    final masterPassword = await showMasterPasswordDialog(
      context,
      title: '输入主密码',
      hintText: '请输入主密码以解密备份数据',
      onVerify: (password) async {
        try {
          // 使用备份中的 salt 派生密钥（异步）
          final testKey = await EncryptionService.deriveKeyAsync(password, saltBytes);
          final testDecrypted = EncryptionService.decrypt(encrypted, testKey);

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

    if (masterPassword == null) return null;

    // 使用主密码和备份的 salt 解密（异步）
    final backupKey = await EncryptionService.deriveKeyAsync(masterPassword, saltBytes);
    final decryptedJson = EncryptionService.decrypt(encrypted, backupKey);

    return _DecryptedDataWithKey(
      json: decryptedJson,
      backupKey: backupKey,
    );
  }
}

/// 解密数据和密钥的包装类
class _DecryptedDataWithKey {
  final String json;
  final Uint8List backupKey;

  _DecryptedDataWithKey({
    required this.json,
    required this.backupKey,
  });
}
