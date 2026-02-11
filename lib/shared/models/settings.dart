import 'package:flutter/material.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';

/// 应用设置模型
class AppSettings {
  final bool biometricEnabled;
  final bool biometricFullUnlock; // 指纹完全解锁（存储加密主密码）
  final Duration autoLockTimeout;
  final Duration passwordVerificationTimeout;
  final bool syncEnabled;
  final SyncConfig? syncConfig;
  final String dataDirectory;
  final Color themeColor;
  final bool autoUpdateEnabled;

  AppSettings({
    required this.biometricEnabled,
    this.biometricFullUnlock = false,
    required this.autoLockTimeout,
    this.passwordVerificationTimeout = const Duration(seconds: 30),
    required this.syncEnabled,
    this.syncConfig,
    required this.dataDirectory,
    required this.themeColor,
    this.autoUpdateEnabled = true,
  });

  AppSettings copyWith({
    bool? biometricEnabled,
    bool? biometricFullUnlock,
    Duration? autoLockTimeout,
    Duration? passwordVerificationTimeout,
    bool? syncEnabled,
    SyncConfig? syncConfig,
    String? dataDirectory,
    Color? themeColor,
    bool? autoUpdateEnabled,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricFullUnlock: biometricFullUnlock ?? this.biometricFullUnlock,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      passwordVerificationTimeout: passwordVerificationTimeout ?? this.passwordVerificationTimeout,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncConfig: syncConfig ?? this.syncConfig,
      dataDirectory: dataDirectory ?? this.dataDirectory,
      themeColor: themeColor ?? this.themeColor,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
    );
  }
}
