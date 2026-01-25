import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_group.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/core/logging/log_service.dart';

/// 使用 Hive 进行本地加密数据持久化的存储服务
class StorageService {
  static const String _passwordsBoxName = 'passwords';
  static const String _groupsBoxName = 'groups';
  static const String _settingsBoxName = 'settings';
  static const String _defaultDataDir = 'vault_safe_data';

  Box<dynamic>? _passwordsBox;
  Box<dynamic>? _groupsBox;
  Box<dynamic>? _settingsBox;

  bool _initialized = false;
  String? _currentDirectory;

  /// 获取当前数据目录
  String? get currentDirectory => _currentDirectory;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 使用自定义目录路径初始化
  Future<void> init({String? customDirectory}) async {
    if (_initialized) {
      log.d('StorageService: 已经初始化，跳过', source: 'StorageService');
      return;
    }

    try {
      String dataPath;

      if (customDirectory != null && customDirectory.isNotEmpty) {
        // 使用自定义目录
        dataPath = customDirectory;
        log.i('StorageService: 使用自定义目录: $dataPath', source: 'StorageService');
      } else {
        // 使用默认目录
        final appDocDir = await getApplicationDocumentsDirectory();
        dataPath = path.join(appDocDir.path, _defaultDataDir);
        log.i('StorageService: 使用默认目录: $dataPath', source: 'StorageService');
      }

      // 确保目录存在
      final dir = Directory(dataPath);
      if (!await dir.exists()) {
        log.d('StorageService: 创建数据目录: $dataPath', source: 'StorageService');
        await dir.create(recursive: true);
      }

      // 验证目录是否可写
      final testFile = File(path.join(dataPath, '.write_test'));
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        log.d('StorageService: 目录可写验证成功', source: 'StorageService');
      } catch (e) {
        log.e('StorageService: 目录不可写!', source: 'StorageService', error: e);
        rethrow;
      }

      _currentDirectory = dataPath;

      // 使用数据路径初始化 Hive
      log.d('StorageService: 初始化 Hive...', source: 'StorageService');
      await Hive.initFlutter(dataPath);

      // 检测并注册 TypeAdapter<EncryptedData>
      if (!Hive.isAdapterRegistered(0)) {
        log.d('StorageService: 注册 EncryptedDataAdapter', source: 'StorageService');
        Hive.registerAdapter(EncryptedDataAdapter());
      }

      // 打开数据表
      log.d('StorageService: 打开 boxes...', source: 'StorageService');
      _passwordsBox = await Hive.openBox(_passwordsBoxName);
      _groupsBox = await Hive.openBox(_groupsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _initialized = true;
      log.i('StorageService: 初始化完成! 数据路径: $dataPath', source: 'StorageService');
      log.i('StorageService: 密码数量: ${_passwordsBox?.length}, 分组数量: ${_groupsBox?.length}', source: 'StorageService');
    } catch (e, stackTrace) {
      log.e('StorageService: 初始化失败!', source: 'StorageService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized || _passwordsBox == null || _groupsBox == null || _settingsBox == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
  }

  /// 获取所有密码条目
  Future<List<PasswordEntry>> getPasswordEntries() async {
    _ensureInitialized();

    final entries = <PasswordEntry>[];
    for (final key in _passwordsBox!.keys) {
      final json = _passwordsBox!.get(key) as Map<dynamic, dynamic>?;
      if (json == null) continue;

      try {
        final entry = PasswordEntry.fromJson(
          Map<String, dynamic>.from(json),
        );
        entries.add(entry);
      } catch (e) {
        // 跳过无效条目
        continue;
      }
    }
    return entries;
  }

  /// 根据 ID 获取单个密码条目
  Future<PasswordEntry?> getPasswordEntry(String id) async {
    _ensureInitialized();

    final json = _passwordsBox!.get(id) as Map<dynamic, dynamic>?;
    if (json == null) return null;

    try {
      return PasswordEntry.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  /// 保存密码条目
  Future<void> savePasswordEntry(PasswordEntry entry) async {
    _ensureInitialized();

    await _passwordsBox!.put(entry.id, entry.toJson());
  }

  /// 删除密码条目
  Future<void> deletePasswordEntry(String id) async {
    _ensureInitialized();

    await _passwordsBox!.delete(id);
  }

  /// 删除所有密码条目
  Future<void> clearPasswordEntries() async {
    _ensureInitialized();

    await _passwordsBox!.clear();
  }

  // ===== 分组 =====

  /// 获取所有分组
  Future<List<PasswordGroup>> getGroups() async {
    _ensureInitialized();

    final groups = <PasswordGroup>[];
    for (final key in _groupsBox!.keys) {
      final json = _groupsBox!.get(key) as Map<dynamic, dynamic>?;
      if (json != null) {
        try {
          final group = PasswordGroup.fromJson(
            Map<String, dynamic>.from(json),
          );
          groups.add(group);
        } catch (e) {
          // 跳过无效条目
          continue;
        }
      }
    }
    return groups;
  }

  /// 根据 ID 获取单个分组
  Future<PasswordGroup?> getGroup(String id) async {
    _ensureInitialized();

    final json = _groupsBox!.get(id) as Map<dynamic, dynamic>?;
    if (json == null) return null;

    try {
      return PasswordGroup.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  /// 保存分组
  Future<void> saveGroup(PasswordGroup group) async {
    _ensureInitialized();

    await _groupsBox!.put(group.id, group.toJson());
  }

  /// 删除分组
  Future<void> deleteGroup(String id) async {
    _ensureInitialized();

    await _groupsBox!.delete(id);
  }

  /// 删除所有分组
  Future<void> clearGroups() async {
    _ensureInitialized();

    await _groupsBox!.clear();
  }

  // ===== 设置 =====

  /// 获取设置值
  Future<T?> getSetting<T>(String key) async {
    _ensureInitialized();

    return _settingsBox!.get(key) as T?;
  }

  /// 设置设置值
  Future<void> setSetting<T>(String key, T value) async {
    _ensureInitialized();

    await _settingsBox!.put(key, value);
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();

    await _settingsBox!.delete(key);
  }

  /// 清除所有设置
  Future<void> clearSettings() async {
    _ensureInitialized();

    await _settingsBox!.clear();
  }

  // ===== 备份/导出 =====

  /// 将所有数据导出为 JSON
  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();

    final entries = await getPasswordEntries();
    final groups = await getGroups();

    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'passwords': entries.map((e) => e.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }

  /// 从 JSON 导入数据
  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();

    final version = data['version'] as String?;
    if (version != '1.0') {
      throw Exception('Unsupported backup version: $version');
    }

    // 导入密码
    final passwordsJson = data['passwords'] as List<dynamic>?;
    if (passwordsJson != null) {
      for (final json in passwordsJson) {
        try {
          final entry = PasswordEntry.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          await savePasswordEntry(entry);
        } catch (e) {
          // 跳过无效条目
          continue;
        }
      }
    }

    // 导入分组
    final groupsJson = data['groups'] as List<dynamic>?;
    if (groupsJson != null) {
      for (final json in groupsJson) {
        try {
          final group = PasswordGroup.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          await saveGroup(group);
        } catch (e) {
          // 跳过无效条目
          continue;
        }
      }
    }
  }

  // ===== 清理 =====

  /// 关闭所有数据表
  Future<void> close() async {
    if (!_initialized) return;

    await _passwordsBox?.close();
    await _groupsBox?.close();
    await _settingsBox?.close();

    _passwordsBox = null;
    _groupsBox = null;
    _settingsBox = null;
    _initialized = false;
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    _ensureInitialized();

    await clearPasswordEntries();
    await clearGroups();
    await clearSettings();
  }

  /// 更改数据目录并迁移数据
  Future<void> changeDataDirectory(String newDirectory) async {
    if (!_initialized) {
      throw Exception('StorageService not initialized. Call init() first.');
    }

    // 导出当前数据
    final data = await exportData();

    // 关闭当前数据表
    await close();

    // 使用新目录重新初始化
    await init(customDirectory: newDirectory);

    // 导入数据
    await importData(data);
  }
}

/// EncryptedData 的 Hive TypeAdapter
class EncryptedDataAdapter extends TypeAdapter<EncryptedData> {
  @override
  final int typeId = 0;

  @override
  EncryptedData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EncryptedData(
      nonce: fields[0] as String,
      ciphertext: fields[1] as String,
      tag: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EncryptedData obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.nonce);
    writer.writeByte(1);
    writer.write(obj.ciphertext);
    writer.writeByte(2);
    writer.write(obj.tag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      other is EncryptedDataAdapter && other.typeId == typeId;
}
