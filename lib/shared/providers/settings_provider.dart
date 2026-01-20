import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultafe/shared/models/settings.dart';

/// Settings notifier
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Load from persistent storage
      final settings = AppSettings(
        biometricEnabled: false,
        autoLockTimeout: const Duration(minutes: 1),
        syncEnabled: false,
        syncConfig: null,
      );
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBiometricEnabled(bool value) async {
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(biometricEnabled: value));
      // TODO: Persist to storage
    });
  }

  Future<void> updateAutoLockTimeout(Duration timeout) async {
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(autoLockTimeout: timeout));
      // TODO: Persist to storage
    });
  }

  Future<void> updateSyncEnabled(bool value) async {
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(syncEnabled: value));
      // TODO: Persist to storage
    });
  }

  Future<void> updateSyncConfig(SyncConfig config) async {
    state.whenData((settings) {
      state = AsyncValue.data(settings.copyWith(syncConfig: config));
      // TODO: Persist encrypted config to storage
    });
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});
