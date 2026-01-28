import 'package:flutter/material.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';

/// 应用设置模型
class AppSettings {
  final bool biometricEnabled;
  final Duration autoLockTimeout;
  final bool syncEnabled;
  final SyncConfig? syncConfig;
  final String dataDirectory;
  final Color themeColor;

  AppSettings({
    required this.biometricEnabled,
    required this.autoLockTimeout,
    required this.syncEnabled,
    this.syncConfig,
    required this.dataDirectory,
    required this.themeColor,
  });

  AppSettings copyWith({
    bool? biometricEnabled,
    Duration? autoLockTimeout,
    bool? syncEnabled,
    SyncConfig? syncConfig,
    String? dataDirectory,
    Color? themeColor,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncConfig: syncConfig ?? this.syncConfig,
      dataDirectory: dataDirectory ?? this.dataDirectory,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
