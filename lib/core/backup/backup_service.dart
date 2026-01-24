import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';

/// 备份服务 - 处理加密导出/导入功能
class BackupService {
  final StorageService _storageService;

  BackupService(this._storageService);

  /// 导出加密备份文件
  /// 返回导出文件的完整路径
  Future<File> exportEncryptedBackup(Uint8List masterKey) async {
    // 1. 从存储服务获取所有数据
    final data = await _storageService.exportData();

    // 2. 将数据序列化为 JSON 字符串
    final jsonString = jsonEncode(data);

    // 3. 使用主密钥加密整个 JSON
    final encrypted = EncryptionService.encrypt(jsonString, masterKey);

    // 4. 创建备份数据结构
    final backupData = {
      'version': '1.0',
      'format': 'vaultsafe-encrypted',
      'encrypted': true,
      'data': encrypted.toJson(),
      'checksum': _calculateChecksum(jsonString),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    // 5. 获取下载目录（根据平台）
    final directory = await _getBackupDirectory();

    // 6. 生成文件名（带时间戳）
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final filename = 'vaultsafe_backup_$timestamp.json';
    final filePath = path.join(directory.path, filename);

    // 7. 写入文件
    final file = File(filePath);
    await file.writeAsString(jsonEncode(backupData));

    return file;
  }

  /// 导入加密备份文件
  /// 验证并解密备份文件，然后导入到存储服务
  Future<ImportResult> importEncryptedBackup(File backupFile, Uint8List masterKey) async {
    try {
      // 1. 读取备份文件
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 2. 验证备份格式
      final version = backupData['version'] as String?;
      if (version != '1.0') {
        return ImportResult(
          success: false,
          error: '不支持的备份版本: $version',
        );
      }

      final isEncrypted = backupData['encrypted'] as bool? ?? false;
      if (!isEncrypted) {
        return ImportResult(
          success: false,
          error: '备份文件未加密',
        );
      }

      // 3. 解密数据
      final encryptedData = backupData['data'] as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(encryptedData);

      String decryptedJson;
      try {
        decryptedJson = EncryptionService.decrypt(encrypted, masterKey);
      } catch (e) {
        return ImportResult(
          success: false,
          error: '解密失败: 主密码不正确或备份文件已损坏',
        );
      }

      // 4. 验证校验和
      final storedChecksum = backupData['checksum'] as String?;
      final calculatedChecksum = _calculateChecksum(decryptedJson);
      if (storedChecksum != null && storedChecksum != calculatedChecksum) {
        return ImportResult(
          success: false,
          error: '备份文件校验和不匹配，文件可能已损坏',
        );
      }

      // 5. 解析并导入数据
      final data = jsonDecode(decryptedJson) as Map<String, dynamic>;
      await _storageService.importData(data);

      return ImportResult(
        success: true,
        passwordCount: (data['passwords'] as List?)?.length ?? 0,
        groupCount: (data['groups'] as List?)?.length ?? 0,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: '导入失败: $e',
      );
    }
  }

  /// 导出未加密备份（JSON 格式，用于测试或迁移）
  /// 警告：此方法导出的是加密的密码条目，但密码本身仍是加密状态
  Future<File> exportUnencryptedBackup() async {
    final data = await _storageService.exportData();
    final jsonString = jsonEncode(data);

    final directory = await _getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final filename = 'vaultsafe_backup_unencrypted_$timestamp.json';
    final filePath = path.join(directory.path, filename);

    final file = File(filePath);
    await file.writeAsString(jsonString);

    return file;
  }

  /// 获取备份文件的基本信息（不导入）
  /// 用于在导入前显示预览信息
  Future<BackupInfo?> getBackupInfo(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      return BackupInfo(
        version: backupData['version'] as String? ?? 'unknown',
        isEncrypted: backupData['encrypted'] as bool? ?? false,
        exportedAt: backupData['exportedAt'] as String?,
        fileSize: await backupFile.length(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 计算校验和（SHA-256）
  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 获取备份存储目录
  Future<Directory> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      // Android: 使用 Download 目录
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        return directory;
      }
      // 回退到外部存储目录
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: 使用应用文档目录
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台: 使用下载目录
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        return directory;
      }
      return await getApplicationDocumentsDirectory();
    }

    // 默认回退
    return await getApplicationDocumentsDirectory();
  }

  /// 清理旧备份文件（保留最近 N 个）
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final directory = await _getBackupDirectory();

      // 查找所有备份文件
      final files = directory.listSync()
          .whereType<File>()
          .where((f) => path.basename(f.path).startsWith('vaultsafe_backup_'))
          .toList();

      // 按修改时间排序（最新的在前）
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除超过保留数量的文件
      if (files.length > keepCount) {
        for (var i = keepCount; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      // 静默失败，不影响主要功能
      debugPrint('清理备份文件失败: $e');
    }
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String? error;
  final int? passwordCount;
  final int? groupCount;

  ImportResult({
    required this.success,
    this.error,
    this.passwordCount,
    this.groupCount,
  });

  @override
  String toString() {
    if (success) {
      return '导入成功: $passwordCount 个密码, $groupCount 个分组';
    }
    return '导入失败: $error';
  }
}

/// 备份文件信息
class BackupInfo {
  final String version;
  final bool isEncrypted;
  final String? exportedAt;
  final int fileSize;

  BackupInfo({
    required this.version,
    required this.isEncrypted,
    this.exportedAt,
    required this.fileSize,
  });

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String? get formattedExportDate {
    if (exportedAt == null) return null;
    try {
      final date = DateTime.parse(exportedAt!);
      return date.toLocal().toString().split('.')[0];
    } catch (e) {
      return exportedAt;
    }
  }
}
