import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vaultsafe/core/update/version_info.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/core/config/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 更新检查服务
class UpdateService {
  final String updateUrl;
  final LogService log = LogService.instance;
  final Dio _dio = Dio();

  UpdateService({String? updateUrl})
      : updateUrl = updateUrl ?? ConfigService.instance.config.updateServer {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// 检查更新
  Future<UpdateCheckResult> checkUpdate({bool? includeDataUpdates}) async {
    try {
      log.i('开始检查更新...', source: 'UpdateService');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = AppVersion.fromString(packageInfo.version);

      final response = await _dio.get(
        '$updateUrl/check',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-App-Version': packageInfo.version,
            'X-Platform': _getPlatform(),
            'X-Architecture': _getArchitecture(),
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);

        log.i('收到更新信息: ${updateInfo.version}', source: 'UpdateService');

        return UpdateCheckResult(
          hasUpdate: updateInfo.parsedVersion > currentVersion,
          updateInfo: updateInfo,
          currentVersion: currentVersion,
        );
      } else if (response.statusCode == 204) {
        log.i('当前已是最新版本', source: 'UpdateService');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
        );
      } else {
        throw Exception('检查更新失败: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      log.e('检查更新失败', source: 'UpdateService', error: e, stackTrace: st);

      final packageInfo = await PackageInfo.fromPlatform();
      return UpdateCheckResult(
        hasUpdate: false,
        error: e.toString(),
        currentVersion: AppVersion.fromString(packageInfo.version),
      );
    }
  }

  /// 获取当前平台
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 获取系统架构
  String _getArchitecture() {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'x64';
    if (Platform.isMacOS) return 'arm64';
    if (Platform.isLinux) {
      return 'x64'; // 简化处理
    }
    return 'unknown';
  }
}

/// 更新检查结果
class UpdateCheckResult {
  final bool hasUpdate;
  final UpdateInfo? updateInfo;
  final AppVersion? currentVersion;
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.updateInfo,
    this.currentVersion,
    this.error,
  });
}
