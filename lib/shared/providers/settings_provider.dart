import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/shared/models/settings.dart';

/// 设置通知器
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

      final settings = AppSettings(
        biometricEnabled: biometricEnabled,
        autoLockTimeout: Duration(seconds: autoLockSeconds),
        syncEnabled: syncEnabled,
        syncConfig: syncConfig,
        dataDirectory: dataDirectory,
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
}

/// 设置提供者
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});
