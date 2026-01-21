import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/shared/models/settings.dart';

/// Settings notifier
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      // Load settings from secure storage
      final biometricEnabled = await _storage.read(key: 'biometric_enabled') == 'true';
      final autoLockSeconds = int.tryParse(await _storage.read(key: 'auto_lock_timeout') ?? '60') ?? 60;
      final syncEnabled = await _storage.read(key: 'sync_enabled') == 'true';

      // Load sync config
      SyncConfig? syncConfig;
      final syncConfigJson = await _storage.read(key: 'sync_config');
      if (syncConfigJson != null) {
        try {
          syncConfig = SyncConfig.fromJson(jsonDecode(syncConfigJson));
        } catch (e) {
          // If sync config is corrupted, ignore it
        }
      }

      final settings = AppSettings(
        biometricEnabled: biometricEnabled,
        autoLockTimeout: Duration(seconds: autoLockSeconds),
        syncEnabled: syncEnabled,
        syncConfig: syncConfig,
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
    // Store sync config as JSON
    await _storage.write(key: 'sync_config', value: jsonEncode(config.toJson()));
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(syncConfig: config));
    });
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});
