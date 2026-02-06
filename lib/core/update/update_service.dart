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
    // 调试：输出配置信息
    log.d('UpdateService initialized', source: 'UpdateService');
    log.d('updateUrl = "$updateUrl"', source: 'UpdateService');
    log.d('ConfigService.config.updateServer = "${ConfigService.instance.config.updateServer}"', source: 'UpdateService');
    log.d('Config file path: ${ConfigService.instance.configFilePath}', source: 'UpdateService');
  }

  /// 检查更新
  Future<UpdateCheckResult> checkUpdate() async {
    try {
      // 检查更新服务器是否配置
      if (updateUrl.isEmpty) {
        log.i('更新服务器未配置，跳过更新检查', source: 'UpdateService');
        final packageInfo = await PackageInfo.fromPlatform();
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: AppVersion.fromString(packageInfo.version),
        );
      }

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

      // 生成友好的错误消息
      String friendlyError = _getFriendlyErrorMessage(e);

      return UpdateCheckResult(
        hasUpdate: false,
        error: friendlyError,
        currentVersion: AppVersion.fromString(packageInfo.version),
      );
    }
  }

  /// 根据异常类型生成友好的错误消息
  String _getFriendlyErrorMessage(dynamic error) {
    // 网络连接错误
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '连接超时：服务器响应时间过长，请稍后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 404) {
            return '更新服务不可用 (HTTP 404)：服务器地址可能未配置或不存在';
          } else if (statusCode == 500) {
            return '服务器内部错误 (HTTP 500)：更新服务器出现故障';
          } else if (statusCode == 502 || statusCode == 503) {
            return '服务暂时不可用 (HTTP $statusCode)：服务器维护中，请稍后重试';
          } else {
            return '服务器返回错误 (HTTP $statusCode)：${error.message}';
          }

        case DioExceptionType.cancel:
          return '请求已取消';

        case DioExceptionType.connectionError:
          return '网络连接失败：无法连接到更新服务器，请检查网络连接';

        case DioExceptionType.unknown:
          // 检查是否是底层网络错误
          if (error.error is SocketException) {
            return '网络连接失败：请检查网络连接或服务器地址';
          }
          return '网络错误：${error.message}';

        default:
          return '请求失败：${error.message}';
      }
    }

    // Socket 异常
    if (error is SocketException) {
      return '网络连接失败：无法访问更新服务器，请检查网络设置';
    }

    // HTTP 异常
    if (error is HttpException) {
      return 'HTTP错误：${error.message}';
    }

    // 格式化异常
    if (error is FormatException) {
      return '数据格式错误：服务器返回的数据格式不正确';
    }

    // 其他错误
    return '检查更新时发生错误：${error.toString()}';
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
