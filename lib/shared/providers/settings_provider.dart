import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/shared/models/settings.dart';

/// 设置通知器
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 预定义主题颜色列表
  static const List<Color> _themeColors = [
    Color(0xFF2196F3), // 蓝色
    Color(0xFF4CAF50), // 绿色
    Color(0xFFFF9800), // 橙色
    Color(0xFFE91E63), // 粉色
    Color(0xFF9C27B0), // 紫色
    Color(0xFF00BCD4), // 青色
    Color(0xFFFF5722), // 深橙色
    Color(0xFF607D8B), // 蓝灰色
  ];

  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      // 从安全存储加载设置
      final biometricEnabled = await _storage.read(key: 'biometric_enabled') == 'true';
      final autoLockSeconds = int.tryParse(await _storage.read(key: 'auto_lock_timeout') ?? '60') ?? 60;
      final syncEnabled = await _storage.read(key: 'sync_enabled') == 'true';

      // 加载同步配置
      SyncConfig? syncConfig;
      final syncConfigJson = await _storage.read(key: 'sync_config');
      if (syncConfigJson != null) {
        try {
          syncConfig = SyncConfig.fromJson(jsonDecode(syncConfigJson));
        } catch (e) {
          // 如果同步配置损坏，忽略它
        }
      }

      // 加载数据目录
      String dataDirectory = await _storage.read(key: 'data_directory') ?? '';
      if (dataDirectory.isEmpty) {
        // 使用默认目录
        final appDocDir = await getApplicationDocumentsDirectory();
        dataDirectory = path.join(appDocDir.path, 'vault_safe_data');
      }

      // 加载主题颜色
      final themeColorValue = await _storage.read(key: 'theme_color');
      Color themeColor = const Color(0xFF2196F3); // 默认蓝色
      if (themeColorValue != null) {
        try {
          final colorValue = int.tryParse(themeColorValue);
          if (colorValue != null) {
            themeColor = Color(colorValue);
          }
        } catch (e) {
          // 如果颜色值无效，使用默认颜色
        }
      }

      final settings = AppSettings(
        biometricEnabled: biometricEnabled,
        autoLockTimeout: Duration(seconds: autoLockSeconds),
        syncEnabled: syncEnabled,
        syncConfig: syncConfig,
        dataDirectory: dataDirectory,
        themeColor: themeColor,
      );
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBiometricEnabled(bool value) async {
    await _storage.write(key: 'biometric_enabled', value: value.toString());
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(biometricEnabled: value));
    });
  }

  Future<void> updateAutoLockTimeout(Duration timeout) async {
    await _storage.write(key: 'auto_lock_timeout', value: timeout.inSeconds.toString());
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(autoLockTimeout: timeout));
    });
  }

  Future<void> updateSyncEnabled(bool value) async {
    await _storage.write(key: 'sync_enabled', value: value.toString());
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(syncEnabled: value));
    });
  }

  Future<void> updateSyncConfig(SyncConfig config) async {
    // 将同步配置存储为 JSON
    await _storage.write(key: 'sync_config', value: jsonEncode(config.toJson()));
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(syncConfig: config));
    });
  }

  Future<void> updateDataDirectory(String directory) async {
    await _storage.write(key: 'data_directory', value: directory);
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(dataDirectory: directory));
    });
  }

  Future<void> updateThemeColor(Color color) async {
    await _storage.write(key: 'theme_color', value: color.toARGB32().toString());
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(themeColor: color));
    });
  }

  /// 获取可用的主题颜色列表
  static List<Color> get availableThemeColors => List.unmodifiable(_themeColors);
}

/// 设置提供者
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});
