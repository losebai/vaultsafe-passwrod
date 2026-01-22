import 'package:vaultsafe/core/sync/sync_config.dart';

/// 应用设置模型
class AppSettings {
  final bool biometricEnabled;
  final Duration autoLockTimeout;
  final bool syncEnabled;
  final SyncConfig? syncConfig;
  final String dataDirectory;

  AppSettings({
    required this.biometricEnabled,
    required this.autoLockTimeout,
    required this.syncEnabled,
    this.syncConfig,
    required this.dataDirectory,
  });

  AppSettings copyWith({
    bool? biometricEnabled,
    Duration? autoLockTimeout,
    bool? syncEnabled,
    SyncConfig? syncConfig,
    String? dataDirectory,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncConfig: syncConfig ?? this.syncConfig,
      dataDirectory: dataDirectory ?? this.dataDirectory,
    );
  }
}
