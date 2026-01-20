import 'package:vaultsafe/core/sync/sync_config.dart';

/// App settings model
class AppSettings {
  final bool biometricEnabled;
  final Duration autoLockTimeout;
  final bool syncEnabled;
  final SyncConfig? syncConfig;

  AppSettings({
    required this.biometricEnabled,
    required this.autoLockTimeout,
    required this.syncEnabled,
    this.syncConfig,
  });

  AppSettings copyWith({
    bool? biometricEnabled,
    Duration? autoLockTimeout,
    bool? syncEnabled,
    SyncConfig? syncConfig,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncConfig: syncConfig ?? this.syncConfig,
    );
  }
}
