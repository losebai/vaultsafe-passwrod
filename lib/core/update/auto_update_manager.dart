import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vaultsafe/core/update/version_info.dart';
import 'package:vaultsafe/core/update/update_service.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 自动更新管理器
class AutoUpdateManager {
  static const String _lastCheckKey = 'last_update_check';
  static const String _lastCheckVersionKey = 'last_check_version';
  static const Duration _checkInterval = Duration(hours: 24); // 每24小时检查一次

  final UpdateService _updateService;
  final LogService log = LogService.instance;

  Timer? _checkTimer;

  AutoUpdateManager({String? updateUrl})
      : _updateService = UpdateService(updateUrl: updateUrl);

  /// 初始化自动更新
  Future<void> initialize({bool autoCheck = true}) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      log.i('初始化桌面端自动更新', source: 'AutoUpdateManager');

      // 检查上次检查时间
      if (autoCheck) {
        await _checkIfNeeded();
      }

      // 启动定期检查
      _startPeriodicCheck();
    }
  }

  /// 启动定期检查
  void _startPeriodicCheck() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _checkTimer?.cancel();
      _checkTimer = Timer.periodic(_checkInterval, (timer) {
        log.i('定期检查更新', source: 'AutoUpdateManager');
        checkUpdate(showNotification: true);
      });
    }
  }

  /// 根据上次检查时间决定是否需要检查
  Future<void> _checkIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastCheckKey);

      if (lastCheckStr == null) {
        // 首次运行，立即检查
        log.i('首次运行，检查更新', source: 'AutoUpdateManager');
        await checkUpdate();
        return;
      }

      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();
      final timeSinceLastCheck = now.difference(lastCheck);

      // 距离上次检查已超过24小时，或者上次检查的版本与当前不同
      if (timeSinceLastCheck > _checkInterval) {
        log.i('距离上次检查已超过24小时，重新检查', source: 'AutoUpdateManager');
        await checkUpdate();
      } else {
        log.i('距离上次检查不足24小时，跳过自动检查', source: 'AutoUpdateManager');
      }
    } catch (e, st) {
      log.e('检查上次更新时间失败', source: 'AutoUpdateManager', error: e, stackTrace: st);
    }
  }

  /// 检查更新
  Future<UpdateCheckResult?> checkUpdate({bool showNotification = false}) async {
    try {
      log.i('开始检查更新', source: 'AutoUpdateManager');

      final result = await _updateService.checkUpdate();

      // 保存检查时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
      if (result.currentVersion != null) {
        await prefs.setString(_lastCheckVersionKey, result.currentVersion!.toString());
      }

      if (result.hasUpdate && result.updateInfo != null) {
        log.i('发现新版本: ${result.updateInfo!.version}', source: 'AutoUpdateManager');

        // 如果是强制更新或启用了通知，显示更新提示
        if (result.updateInfo!.forceUpdate || showNotification) {
          _showUpdateNotification(result.updateInfo!);
        }

        return result;
      } else {
        log.i('当前已是最新版本', source: 'AutoUpdateManager');
      }

      return result;
    } catch (e, st) {
      log.e('自动检查更新失败', source: 'AutoUpdateManager', error: e, stackTrace: st);
      return null;
    }
  }

  /// 显示更新通知
  void _showUpdateNotification(UpdateInfo updateInfo) {
    // TODO: 实现系统通知
    // 桌面端可以使用 system_tray 或 local_notifier 插件
    log.i('显示更新通知: ${updateInfo.version}', source: 'AutoUpdateManager');
  }

  /// 停止自动更新
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}

/// 自动更新 Provider
final autoUpdateManagerProvider = Provider<AutoUpdateManager>((ref) {
  final manager = AutoUpdateManager();

  // 监听设置变化
  ref.listen(settingsProvider, (previous, next) {
    next.whenData((data) {
      if (data.autoUpdateEnabled) {
        manager.initialize();
      } else {
        manager.dispose();
      }
    });
  });

  return manager;
});

/// 自动更新状态 Provider
final autoUpdateStatusProvider = StreamProvider<UpdateCheckResult?>((ref) {
  final controller = StreamController<UpdateCheckResult?>();

  // 启动时检查更新
  ref.read(autoUpdateManagerProvider).initialize().then((_) {
    // 可以在这里触发 UI 更新
  });

  return controller.stream;
});
