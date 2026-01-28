import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:vaultsafe/core/config/app_config.dart';
import 'package:vaultsafe/core/logging/log_service.dart';

/// 配置更新服务
/// 用于在应用更新时自动下载和更新配置文件
class ConfigUpdater {
  final LogService log = LogService.instance;
  final Dio _dio = Dio();

  /// 从服务器下载并更新配置
  ///
  /// [configUrl] - 配置文件的URL地址
  /// [forceUpdate] - 是否强制更新（即使版本号相同）
  ///
  /// 返回 true 表示配置已更新，false 表示无需更新或更新失败
  Future<bool> updateConfigFromServer(String configUrl, {bool forceUpdate = false}) async {
    try {
      log.i('开始从服务器更新配置: $configUrl', source: 'ConfigUpdater');

      // 下载服务器配置
      final response = await _dio.get(
        configUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200) {
        log.e('下载配置文件失败: HTTP ${response.statusCode}', source: 'ConfigUpdater');
        return false;
      }

      final serverConfigYaml = response.data as String;
      final serverConfig = loadYaml(serverConfigYaml) as YamlMap;

      // 获取当前本地配置
      final configService = ConfigService.instance;

      // 检查版本号
      final serverVersion = serverConfig['app']?['version'] ?? '0.0.0';
      const localVersion = '1.0.0'; // 可以从本地配置读取

      if (!forceUpdate && serverVersion == localVersion) {
        log.i('配置版本相同，无需更新: $serverVersion', source: 'ConfigUpdater');
        return false;
      }

      log.i('发现新配置版本: $localVersion -> $serverVersion', source: 'ConfigUpdater');

      // 解析服务器配置
      final newConfig = AppConfig.fromYaml(serverConfig);

      // 保存新配置
      await configService.updateConfig(newConfig);

      log.i('配置更新成功', source: 'ConfigUpdater');
      return true;
    } catch (e, st) {
      log.e('更新配置失败', source: 'ConfigUpdater', error: e, stackTrace: st);
      return false;
    }
  }

  /// 下载配置文件到本地（不应用）
  Future<String?> downloadConfigFile(String configUrl) async {
    try {
      log.i('下载配置文件: $configUrl', source: 'ConfigUpdater');

      final response = await _dio.get(
        configUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200) {
        log.e('下载配置文件失败: HTTP ${response.statusCode}', source: 'ConfigUpdater');
        return null;
      }

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(tempDir.path, 'config_$timestamp.yaml');

      final file = File(filePath);
      await file.writeAsString(response.data as String);

      log.i('配置文件已下载到: $filePath', source: 'ConfigUpdater');
      return filePath;
    } catch (e, st) {
      log.e('下载配置文件失败', source: 'ConfigUpdater', error: e, stackTrace: st);
      return null;
    }
  }

  /// 从本地文件应用配置
  Future<bool> applyConfigFromFile(String filePath) async {
    try {
      log.i('从文件应用配置: $filePath', source: 'ConfigUpdater');

      final file = File(filePath);
      if (!await file.exists()) {
        log.e('配置文件不存在: $filePath', source: 'ConfigUpdater');
        return false;
      }

      final configString = await file.readAsString();
      final yaml = loadYaml(configString) as YamlMap;
      final newConfig = AppConfig.fromYaml(yaml);

      final configService = ConfigService.instance;
      await configService.updateConfig(newConfig);

      log.i('配置应用成功', source: 'ConfigUpdater');
      return true;
    } catch (e, st) {
      log.e('应用配置失败', source: 'ConfigUpdater', error: e, stackTrace: st);
      return false;
    }
  }

  /// 导出当前配置到文件
  Future<String?> exportCurrentConfig() async {
    try {
      log.i('导出当前配置', source: 'ConfigUpdater');

      final configService = ConfigService.instance;
      final config = configService.config;

      // 保存到下载目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(tempDir.path, 'app_config_backup_$timestamp.yaml');

      final file = File(filePath);
      await file.writeAsString(config.toYamlString());

      log.i('配置已导出到: $filePath', source: 'ConfigUpdater');
      return filePath;
    } catch (e, st) {
      log.e('导出配置失败', source: 'ConfigUpdater', error: e, stackTrace: st);
      return null;
    }
  }

  /// 比较两个配置的差异
  Map<String, dynamic> compareConfigs(AppConfig oldConfig, AppConfig newConfig) {
    return {
      'versionChanged': true, // 可以添加更详细的比较
      'apiChanged': oldConfig.updateServer != newConfig.updateServer,
      'securityChanged': oldConfig.encryptionSalt != newConfig.encryptionSalt,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 验证配置文件格式
  bool validateConfigFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      final content = file.readAsStringSync();
      final yaml = loadYaml(content);

      // 检查必要的键
      if (yaml is! YamlMap) return false;
      if (!yaml.containsKey('app')) return false;
      if (!yaml.containsKey('api')) return false;
      if (!yaml.containsKey('security')) return false;

      return true;
    } catch (e) {
      log.w('配置文件验证失败: $e', source: 'ConfigUpdater');
      return false;
    }
  }
}
