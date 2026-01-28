import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/core/config/app_config.dart';
import 'package:vaultsafe/core/config/config_updater.dart';

/// 更新安装器
class UpdateInstaller {
  final LogService log = LogService.instance;
  final ConfigUpdater _configUpdater = ConfigUpdater();

  /// 安装更新
  Future<bool> installUpdate(String filePath, {bool updateConfig = true}) async {
    try {
      log.i('开始安装更新: $filePath', source: 'UpdateInstaller');

      if (kIsWeb) {
        log.w('Web 平台不支持自动安装更新', source: 'UpdateInstaller');
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        log.e('更新文件不存在: $filePath', source: 'UpdateInstaller');
        return false;
      }

      // 在安装更新前尝试更新配置
      if (updateConfig) {
        await _updateAppConfig();
      }

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return await _installDesktopUpdate(filePath);
      } else if (Platform.isAndroid || Platform.isIOS) {
        log.i('移动平台更新需要通过应用商店', source: 'UpdateInstaller');
        return false;
      }

      return false;
    } catch (e, st) {
      log.e('安装更新失败', source: 'UpdateInstaller', error: e, stackTrace: st);
      return false;
    }
  }

  /// 更新应用配置
  Future<void> _updateAppConfig() async {
    try {
      final configService = ConfigService.instance;
      final configUrl = configService.config.updateServer;

      // 尝试从更新服务器获取配置文件
      // 假设配置文件在: https://api.yourserver.com/v1/update/config
      final configFileUrl = configUrl.replaceFirst('/v1/update', '/v1/config/app_config.yaml');

      log.i('检查配置更新: $configFileUrl', source: 'UpdateInstaller');

      final updated = await _configUpdater.updateConfigFromServer(configFileUrl);

      if (updated) {
        log.i('应用配置已自动更新', source: 'UpdateInstaller');
      } else {
        log.i('配置无需更新或更新失败', source: 'UpdateInstaller');
      }
    } catch (e) {
      // 配置更新失败不应该阻止更新安装
      log.w('配置更新失败，继续安装更新: $e', source: 'UpdateInstaller');
    }
  }

  /// 安装桌面端更新
  Future<bool> _installDesktopUpdate(String filePath) async {
    try {
      if (Platform.isWindows) {
        return await _installWindowsUpdate(filePath);
      } else if (Platform.isMacOS) {
        return await _installMacOSUpdate(filePath);
      } else if (Platform.isLinux) {
        return await _installLinuxUpdate(filePath);
      }
      return false;
    } catch (e, st) {
      log.e('桌面端更新安装失败', source: 'UpdateInstaller', error: e, stackTrace: st);
      return false;
    }
  }

  /// 安装 Windows 更新
  Future<bool> _installWindowsUpdate(String filePath) async {
    try {
      log.i('安装 Windows 更新', source: 'UpdateInstaller');

      // 直接打开安装程序
      final result = await OpenFilex.open(filePath);

      if (result.type == ResultType.done) {
        log.i('成功启动安装程序', source: 'UpdateInstaller');
        return true;
      } else {
        log.e('启动安装程序失败: ${result.message}', source: 'UpdateInstaller');
        return false;
      }
    } catch (e, st) {
      log.e('Windows 更新安装失败', source: 'UpdateInstaller', error: e, stackTrace: st);
      return false;
    }
  }

  /// 安装 macOS 更新
  Future<bool> _installMacOSUpdate(String filePath) async {
    try {
      log.i('安装 macOS 更新', source: 'UpdateInstaller');

      if (filePath.endsWith('.dmg')) {
        // 打开 DMG 文件
        final result = await OpenFilex.open(filePath);

        if (result.type == ResultType.done) {
          log.i('成功打开 DMG 文件', source: 'UpdateInstaller');
          return true;
        } else {
          log.e('打开 DMG 文件失败: ${result.message}', source: 'UpdateInstaller');
          return false;
        }
      } else if (filePath.endsWith('.app')) {
        // 直接打开 .app 文件
        await Process.run('open', [filePath]);
        log.i('成功打开 .app 文件', source: 'UpdateInstaller');
        return true;
      }

      log.w('不支持的 macOS 更新文件格式', source: 'UpdateInstaller');
      return false;
    } catch (e, st) {
      log.e('macOS 更新安装失败', source: 'UpdateInstaller', error: e, stackTrace: st);
      return false;
    }
  }

  /// 安装 Linux 更新
  Future<bool> _installLinuxUpdate(String filePath) async {
    try {
      log.i('安装 Linux 更新', source: 'UpdateInstaller');

      if (filePath.endsWith('.AppImage')) {
        // 给 AppImage 添加执行权限并运行
        await Process.run('chmod', ['+x', filePath]);
        final result = await OpenFilex.open(filePath);

        if (result.type == ResultType.done) {
          log.i('成功启动 AppImage', source: 'UpdateInstaller');
          return true;
        } else {
          log.e('启动 AppImage 失败: ${result.message}', source: 'UpdateInstaller');
          return false;
        }
      } else if (filePath.endsWith('.deb')) {
        // 使用 dpkg 或 gdebi 安装 deb 包
        final result = await Process.run('xdg-open', [filePath]);
        if (result.exitCode == 0) {
          log.i('成功打开 deb 包', source: 'UpdateInstaller');
          return true;
        }
        return false;
      } else if (filePath.endsWith('.rpm')) {
        // 使用 rpm 或 dnf 安装 rpm 包
        final result = await Process.run('xdg-open', [filePath]);
        if (result.exitCode == 0) {
          log.i('成功打开 rpm 包', source: 'UpdateInstaller');
          return true;
        }
        return false;
      }

      // 尝试使用 xdg-open 打开文件
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e, st) {
      log.e('Linux 更新安装失败', source: 'UpdateInstaller', error: e, stackTrace: st);
      return false;
    }
  }

  /// 获取更新文件扩展名
  static String getUpdateFileExtension() {
    if (Platform.isWindows) {
      return '.exe';
    } else if (Platform.isMacOS) {
      return '.dmg';
    } else if (Platform.isLinux) {
      return '.AppImage';
    }
    return '';
  }
}
