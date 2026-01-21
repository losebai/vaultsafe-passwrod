import 'package:hive_flutter/hive_flutter.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_group.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';

/// Storage service using Hive for local encrypted data persistence
class StorageService {
  static const String _passwordsBoxName = 'passwords';
  static const String _groupsBoxName = 'groups';
  static const String _settingsBoxName = 'settings';

  late Box<dynamic> _passwordsBox;
  late Box<dynamic> _groupsBox;
  late Box<dynamic> _settingsBox;

  bool _initialized = false;

  /// Initialize 
  Future<void> init() async {
    if (_initialized) return;

    // 设置默认存储路径
    await Hive.initFlutter("vault_safe_data");

    // 检测注册 TypeAdapter<EncryptedData>
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EncryptedDataAdapter());
    }

    // 打开数据表
    _passwordsBox = await Hive.openBox(_passwordsBoxName);
    _groupsBox = await Hive.openBox(_groupsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    _initialized = true;
  }

  /// Ensure initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
  }


  /// Get all password entries
  Future<List<PasswordEntry>> getPasswordEntries() async {
    _ensureInitialized();

    final entries = <PasswordEntry>[];
    for (final key in _passwordsBox.keys) {
      final json = _passwordsBox.get(key) as Map<dynamic, dynamic>;
      if (json != null) {
        try {
          final entry = PasswordEntry.fromJson(
            Map<String, dynamic>.from(json),
          );
          entries.add(entry);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }
    return entries;
  }

  /// Get a single password entry by ID
  Future<PasswordEntry?> getPasswordEntry(String id) async {
    _ensureInitialized();

    final json = _passwordsBox.get(id) as Map<dynamic, dynamic>?;
    if (json == null) return null;

    try {
      return PasswordEntry.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  /// Save a password entry
  Future<void> savePasswordEntry(PasswordEntry entry) async {
    _ensureInitialized();

    await _passwordsBox.put(entry.id, entry.toJson());
  }

  /// Delete a password entry
  Future<void> deletePasswordEntry(String id) async {
    _ensureInitialized();

    await _passwordsBox.delete(id);
  }

  /// Delete all password entries
  Future<void> clearPasswordEntries() async {
    _ensureInitialized();

    await _passwordsBox.clear();
  }

  // ===== Groups =====

  /// Get all groups
  Future<List<PasswordGroup>> getGroups() async {
    _ensureInitialized();

    final groups = <PasswordGroup>[];
    for (final key in _groupsBox.keys) {
      final json = _groupsBox.get(key) as Map<dynamic, dynamic>?;
      if (json != null) {
        try {
          final group = PasswordGroup.fromJson(
            Map<String, dynamic>.from(json),
          );
          groups.add(group);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }
    return groups;
  }

  /// Get a single group by ID
  Future<PasswordGroup?> getGroup(String id) async {
    _ensureInitialized();

    final json = _groupsBox.get(id) as Map<dynamic, dynamic>?;
    if (json == null) return null;

    try {
      return PasswordGroup.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  /// Save a group
  Future<void> saveGroup(PasswordGroup group) async {
    _ensureInitialized();

    await _groupsBox.put(group.id, group.toJson());
  }

  /// Delete a group
  Future<void> deleteGroup(String id) async {
    _ensureInitialized();

    await _groupsBox.delete(id);
  }

  /// Delete all groups
  Future<void> clearGroups() async {
    _ensureInitialized();

    await _groupsBox.clear();
  }

  // ===== Settings =====

  /// Get a setting value
  Future<T?> getSetting<T>(String key) async {
    _ensureInitialized();

    return _settingsBox.get(key) as T?;
  }

  /// Set a setting value
  Future<void> setSetting<T>(String key, T value) async {
    _ensureInitialized();

    await _settingsBox.put(key, value);
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();

    await _settingsBox.delete(key);
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    _ensureInitialized();

    await _settingsBox.clear();
  }

  // ===== Backup/Export =====

  /// Export all data as JSON
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

  /// Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();

    final version = data['version'] as String?;
    if (version != '1.0') {
      throw Exception('Unsupported backup version: $version');
    }

    // Import passwords
    final passwordsJson = data['passwords'] as List<dynamic>?;
    if (passwordsJson != null) {
      for (final json in passwordsJson) {
        try {
          final entry = PasswordEntry.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          await savePasswordEntry(entry);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }

    // Import groups
    final groupsJson = data['groups'] as List<dynamic>?;
    if (groupsJson != null) {
      for (final json in groupsJson) {
        try {
          final group = PasswordGroup.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          await saveGroup(group);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }
  }

  // ===== Cleanup =====

  /// Close all boxes
  Future<void> close() async {
    if (!_initialized) return;

    await _passwordsBox.close();
    await _groupsBox.close();
    await _settingsBox.close();

    _initialized = false;
  }

  /// Clear all data
  Future<void> clearAll() async {
    _ensureInitialized();

    await clearPasswordEntries();
    await clearGroups();
    await clearSettings();
  }
}

/// Hive TypeAdapter for EncryptedData
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
