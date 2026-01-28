import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:vaultsafe/core/logging/log_service.dart';

/// 应用配置类
class AppConfig {
  // API 配置
  final String updateServer;
  final String syncDefaultEndpoint;
  final int syncTimeout;

  // 安全配置
  final String encryptionSalt;
  final int passwordDefaultLength;
  final bool passwordIncludeUppercase;
  final bool passwordIncludeLowercase;
  final bool passwordIncludeNumbers;
  final bool passwordIncludeSymbols;
  final int passwordMinLength;
  final bool passwordRequireUppercase;
  final bool passwordRequireLowercase;
  final bool passwordRequireNumbers;
  final bool passwordRequireSymbols;

  // 自动锁定配置
  final int autoLockDefaultTimeout;
  final List<int> autoLockTimeoutOptions;

  // 同步配置
  final String syncDefaultInterval;
  final int syncMaxRetryCount;
  final int syncRetryDelay;

  // 备份配置
  final int backupMaxCount;
  final String backupFileNameFormat;

  // 数据存储配置
  final String storageDefaultDirName;
  final String storageDatabaseFile;
  final String storageBackupDir;

  // 日志配置
  final String loggingLevel;
  final int loggingMaxFileSize;
  final int loggingMaxFileCount;
  final String loggingFileName;

  // UI 配置
  final int uiDefaultThemeColor;
  final List<int> uiThemeColors;

  // 自动更新配置
  final int autoUpdateCheckInterval;
  final bool autoUpdateEnabled;
  final String autoUpdateDownloadDir;

  // 功能开关
  final bool biometricEnabled;
  final bool syncEnabled;
  final bool autoBackupEnabled;
  final int autoBackupInterval;

  // 网络配置
  final int networkConnectTimeout;
  final int networkReceiveTimeout;
  final int networkMaxConnections;

  // 常量配置
  final String constantsAppId;
  final String constantsEncryptionAlgorithm;
  final String constantsKdfAlgorithm;
  final int constantsKdfIterations;
  final String constantsDataVersion;

  const AppConfig({
    // API
    this.updateServer = 'https://api.yourserver.com/v1/update',
    this.syncDefaultEndpoint = 'https://api.yourserver.com/api/v1/sync',
    this.syncTimeout = 30,

    // 安全
    this.encryptionSalt = 'your-custom-salt-value',
    this.passwordDefaultLength = 16,
    this.passwordIncludeUppercase = true,
    this.passwordIncludeLowercase = true,
    this.passwordIncludeNumbers = true,
    this.passwordIncludeSymbols = true,
    this.passwordMinLength = 8,
    this.passwordRequireUppercase = true,
    this.passwordRequireLowercase = true,
    this.passwordRequireNumbers = true,
    this.passwordRequireSymbols = false,

    // 自动锁定
    this.autoLockDefaultTimeout = 60,
    this.autoLockTimeoutOptions = const [30, 60, 300, 900],

    // 同步
    this.syncDefaultInterval = 'none',
    this.syncMaxRetryCount = 3,
    this.syncRetryDelay = 1000,

    // 备份
    this.backupMaxCount = 5,
    this.backupFileNameFormat = 'vaultsafe_backup_{timestamp}.json',

    // 存储
    this.storageDefaultDirName = 'vault_safe_data',
    this.storageDatabaseFile = 'passwords.db',
    this.storageBackupDir = 'backups',

    // 日志
    this.loggingLevel = 'info',
    this.loggingMaxFileSize = 10,
    this.loggingMaxFileCount = 5,
    this.loggingFileName = 'vaultsafe.log',

    // UI
    this.uiDefaultThemeColor = 0xFF2196F3,
    this.uiThemeColors = const [
      0xFF2196F3, // 蓝色
      0xFF4CAF50, // 绿色
      0xFFFF9800, // 橙色
      0xFFE91E63, // 粉色
      0xFF9C27B0, // 紫色
      0xFF00BCD4, // 青色
      0xFFFF5722, // 深橙色
      0xFF607D8B, // 蓝灰色
    ],

    // 自动更新
    this.autoUpdateCheckInterval = 24,
    this.autoUpdateEnabled = true,
    this.autoUpdateDownloadDir = 'updates',

    // 功能开关
    this.biometricEnabled = true,
    this.syncEnabled = true,
    this.autoBackupEnabled = true,
    this.autoBackupInterval = 24,

    // 网络
    this.networkConnectTimeout = 30,
    this.networkReceiveTimeout = 30,
    this.networkMaxConnections = 10,

    // 常量
    this.constantsAppId = 'com.vaultsafe.app',
    this.constantsEncryptionAlgorithm = 'AES-256-GCM',
    this.constantsKdfAlgorithm = 'PBKDF2',
    this.constantsKdfIterations = 100000,
    this.constantsDataVersion = '1.0',
  });

  /// 从 YAML 映射创建配置
  factory AppConfig.fromYaml(YamlMap yaml) {
    return AppConfig(
      updateServer: yaml['api']['update_server'] ?? 'https://api.yourserver.com/v1/update',
      syncDefaultEndpoint: yaml['api']['sync']['default_endpoint'] ?? 'https://api.yourserver.com/api/v1/sync',
      syncTimeout: yaml['api']['sync']['timeout'] ?? 30,

      encryptionSalt: yaml['security']['encryption_salt'] ?? 'your-custom-salt-value',
      passwordDefaultLength: yaml['security']['password_generator']['default_length'] ?? 16,
      passwordIncludeUppercase: yaml['security']['password_generator']['include_uppercase'] ?? true,
      passwordIncludeLowercase: yaml['security']['password_generator']['include_lowercase'] ?? true,
      passwordIncludeNumbers: yaml['security']['password_generator']['include_numbers'] ?? true,
      passwordIncludeSymbols: yaml['security']['password_generator']['include_symbols'] ?? true,
      passwordMinLength: yaml['security']['password_requirements']['min_length'] ?? 8,
      passwordRequireUppercase: yaml['security']['password_requirements']['require_uppercase'] ?? true,
      passwordRequireLowercase: yaml['security']['password_requirements']['require_lowercase'] ?? true,
      passwordRequireNumbers: yaml['security']['password_requirements']['require_numbers'] ?? true,
      passwordRequireSymbols: yaml['security']['password_requirements']['require_symbols'] ?? false,

      autoLockDefaultTimeout: yaml['auto_lock']['default_timeout'] ?? 60,
      autoLockTimeoutOptions: (yaml['auto_lock']['timeout_options'] as List?)?.cast<int>() ?? [30, 60, 300, 900],

      syncDefaultInterval: yaml['sync']['default_interval'] ?? 'none',
      syncMaxRetryCount: yaml['sync']['max_retry_count'] ?? 3,
      syncRetryDelay: yaml['sync']['retry_delay'] ?? 1000,

      backupMaxCount: yaml['backup']['max_backup_count'] ?? 5,
      backupFileNameFormat: yaml['backup']['file_name_format'] ?? 'vaultsafe_backup_{timestamp}.json',

      storageDefaultDirName: yaml['storage']['default_dir_name'] ?? 'vault_safe_data',
      storageDatabaseFile: yaml['storage']['database_file'] ?? 'passwords.db',
      storageBackupDir: yaml['storage']['backup_dir'] ?? 'backups',

      loggingLevel: yaml['logging']['level'] ?? 'info',
      loggingMaxFileSize: yaml['logging']['max_file_size'] ?? 10,
      loggingMaxFileCount: yaml['logging']['max_file_count'] ?? 5,
      loggingFileName: yaml['logging']['file_name'] ?? 'vaultsafe.log',

      uiDefaultThemeColor: yaml['ui']['default_theme_color'] ?? 0xFF2196F3,
      uiThemeColors: (yaml['ui']['theme_colors'] as List?)?.cast<int>() ?? [
        0xFF2196F3, 0xFF4CAF50, 0xFFFF9800, 0xFFE91E63,
        0xFF9C27B0, 0xFF00BCD4, 0xFFFF5722, 0xFF607D8B,
      ],

      autoUpdateCheckInterval: yaml['auto_update']['check_interval'] ?? 24,
      autoUpdateEnabled: yaml['auto_update']['enabled'] ?? true,
      autoUpdateDownloadDir: yaml['auto_update']['download_dir'] ?? 'updates',

      biometricEnabled: yaml['features']['biometric_enabled'] ?? true,
      syncEnabled: yaml['features']['sync_enabled'] ?? true,
      autoBackupEnabled: yaml['features']['auto_backup_enabled'] ?? true,
      autoBackupInterval: yaml['features']['auto_backup_interval'] ?? 24,

      networkConnectTimeout: yaml['network']['connect_timeout'] ?? 30,
      networkReceiveTimeout: yaml['network']['receive_timeout'] ?? 30,
      networkMaxConnections: yaml['network']['max_connections'] ?? 10,

      constantsAppId: yaml['constants']['app_id'] ?? 'com.vaultsafe.app',
      constantsEncryptionAlgorithm: yaml['constants']['encryption_algorithm'] ?? 'AES-256-GCM',
      constantsKdfAlgorithm: yaml['constants']['kdf_algorithm'] ?? 'PBKDF2',
      constantsKdfIterations: yaml['constants']['kdf_iterations'] ?? 100000,
      constantsDataVersion: yaml['constants']['data_version'] ?? '1.0',
    );
  }

  /// 转换为 YAML 字符串
  String toYamlString() {
    return '''
# VaultSafe 应用配置文件
app:
  name: "VaultSafe"
  version: "1.0.0"

api:
  update_server: "$updateServer"
  sync:
    default_endpoint: "$syncDefaultEndpoint"
    timeout: $syncTimeout

security:
  encryption_salt: "$encryptionSalt"
  password_generator:
    default_length: $passwordDefaultLength
    include_uppercase: $passwordIncludeUppercase
    include_lowercase: $passwordIncludeLowercase
    include_numbers: $passwordIncludeNumbers
    include_symbols: $passwordIncludeSymbols
  password_requirements:
    min_length: $passwordMinLength
    require_uppercase: $passwordRequireUppercase
    require_lowercase: $passwordRequireLowercase
    require_numbers: $passwordRequireNumbers
    require_symbols: $passwordRequireSymbols

auto_lock:
  default_timeout: $autoLockDefaultTimeout
  timeout_options: ${autoLockTimeoutOptions.toString()}

sync:
  default_interval: "$syncDefaultInterval"
  max_retry_count: $syncMaxRetryCount
  retry_delay: $syncRetryDelay

backup:
  max_backup_count: $backupMaxCount
  file_name_format: "$backupFileNameFormat"

storage:
  default_dir_name: "$storageDefaultDirName"
  database_file: "$storageDatabaseFile"
  backup_dir: "$storageBackupDir"

logging:
  level: "$loggingLevel"
  max_file_size: $loggingMaxFileSize
  max_file_count: $loggingMaxFileCount
  file_name: "$loggingFileName"

ui:
  default_theme_color: $uiDefaultThemeColor
  theme_colors: ${uiThemeColors.toString()}

auto_update:
  check_interval: $autoUpdateCheckInterval
  enabled: $autoUpdateEnabled
  download_dir: "$autoUpdateDownloadDir"

features:
  biometric_enabled: $biometricEnabled
  sync_enabled: $syncEnabled
  auto_backup_enabled: $autoBackupEnabled
  auto_backup_interval: $autoBackupInterval

network:
  connect_timeout: $networkConnectTimeout
  receive_timeout: $networkReceiveTimeout
  max_connections: $networkMaxConnections

constants:
  app_id: "$constantsAppId"
  encryption_algorithm: "$constantsEncryptionAlgorithm"
  kdf_algorithm: "$constantsKdfAlgorithm"
  kdf_iterations: $constantsKdfIterations
  data_version: "$constantsDataVersion"
''';
  }

  /// 复制并修改部分配置
  AppConfig copyWith({
    String? updateServer,
    String? syncDefaultEndpoint,
    int? syncTimeout,
    String? encryptionSalt,
    int? passwordDefaultLength,
    bool? passwordIncludeUppercase,
    bool? passwordIncludeLowercase,
    bool? passwordIncludeNumbers,
    bool? passwordIncludeSymbols,
    int? passwordMinLength,
    bool? passwordRequireUppercase,
    bool? passwordRequireLowercase,
    bool? passwordRequireNumbers,
    bool? passwordRequireSymbols,
    int? autoLockDefaultTimeout,
    List<int>? autoLockTimeoutOptions,
    String? syncDefaultInterval,
    int? syncMaxRetryCount,
    int? syncRetryDelay,
    int? backupMaxCount,
    String? backupFileNameFormat,
    String? storageDefaultDirName,
    String? storageDatabaseFile,
    String? storageBackupDir,
    String? loggingLevel,
    int? loggingMaxFileSize,
    int? loggingMaxFileCount,
    String? loggingFileName,
    int? uiDefaultThemeColor,
    List<int>? uiThemeColors,
    int? autoUpdateCheckInterval,
    bool? autoUpdateEnabled,
    String? autoUpdateDownloadDir,
    bool? biometricEnabled,
    bool? syncEnabled,
    bool? autoBackupEnabled,
    int? autoBackupInterval,
    int? networkConnectTimeout,
    int? networkReceiveTimeout,
    int? networkMaxConnections,
    String? constantsAppId,
    String? constantsEncryptionAlgorithm,
    String? constantsKdfAlgorithm,
    int? constantsKdfIterations,
    String? constantsDataVersion,
  }) {
    return AppConfig(
      updateServer: updateServer ?? this.updateServer,
      syncDefaultEndpoint: syncDefaultEndpoint ?? this.syncDefaultEndpoint,
      syncTimeout: syncTimeout ?? this.syncTimeout,
      encryptionSalt: encryptionSalt ?? this.encryptionSalt,
      passwordDefaultLength: passwordDefaultLength ?? this.passwordDefaultLength,
      passwordIncludeUppercase: passwordIncludeUppercase ?? this.passwordIncludeUppercase,
      passwordIncludeLowercase: passwordIncludeLowercase ?? this.passwordIncludeLowercase,
      passwordIncludeNumbers: passwordIncludeNumbers ?? this.passwordIncludeNumbers,
      passwordIncludeSymbols: passwordIncludeSymbols ?? this.passwordIncludeSymbols,
      passwordMinLength: passwordMinLength ?? this.passwordMinLength,
      passwordRequireUppercase: passwordRequireUppercase ?? this.passwordRequireUppercase,
      passwordRequireLowercase: passwordRequireLowercase ?? this.passwordRequireLowercase,
      passwordRequireNumbers: passwordRequireNumbers ?? this.passwordRequireNumbers,
      passwordRequireSymbols: passwordRequireSymbols ?? this.passwordRequireSymbols,
      autoLockDefaultTimeout: autoLockDefaultTimeout ?? this.autoLockDefaultTimeout,
      autoLockTimeoutOptions: autoLockTimeoutOptions ?? this.autoLockTimeoutOptions,
      syncDefaultInterval: syncDefaultInterval ?? this.syncDefaultInterval,
      syncMaxRetryCount: syncMaxRetryCount ?? this.syncMaxRetryCount,
      syncRetryDelay: syncRetryDelay ?? this.syncRetryDelay,
      backupMaxCount: backupMaxCount ?? this.backupMaxCount,
      backupFileNameFormat: backupFileNameFormat ?? this.backupFileNameFormat,
      storageDefaultDirName: storageDefaultDirName ?? this.storageDefaultDirName,
      storageDatabaseFile: storageDatabaseFile ?? this.storageDatabaseFile,
      storageBackupDir: storageBackupDir ?? this.storageBackupDir,
      loggingLevel: loggingLevel ?? this.loggingLevel,
      loggingMaxFileSize: loggingMaxFileSize ?? this.loggingMaxFileSize,
      loggingMaxFileCount: loggingMaxFileCount ?? this.loggingMaxFileCount,
      loggingFileName: loggingFileName ?? this.loggingFileName,
      uiDefaultThemeColor: uiDefaultThemeColor ?? this.uiDefaultThemeColor,
      uiThemeColors: uiThemeColors ?? this.uiThemeColors,
      autoUpdateCheckInterval: autoUpdateCheckInterval ?? this.autoUpdateCheckInterval,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateDownloadDir: autoUpdateDownloadDir ?? this.autoUpdateDownloadDir,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      networkConnectTimeout: networkConnectTimeout ?? this.networkConnectTimeout,
      networkReceiveTimeout: networkReceiveTimeout ?? this.networkReceiveTimeout,
      networkMaxConnections: networkMaxConnections ?? this.networkMaxConnections,
      constantsAppId: constantsAppId ?? this.constantsAppId,
      constantsEncryptionAlgorithm: constantsEncryptionAlgorithm ?? this.constantsEncryptionAlgorithm,
      constantsKdfAlgorithm: constantsKdfAlgorithm ?? this.constantsKdfAlgorithm,
      constantsKdfIterations: constantsKdfIterations ?? this.constantsKdfIterations,
      constantsDataVersion: constantsDataVersion ?? this.constantsDataVersion,
    );
  }
}

/// 配置管理服务
class ConfigService {
  static ConfigService? _instance;
  final LogService log = LogService.instance;

  AppConfig? _config;
  String? _configFilePath;

  ConfigService._();

  static ConfigService get instance {
    _instance ??= ConfigService._();
    return _instance!;
  }

  /// 获取当前配置
  AppConfig get config => _config ?? const AppConfig();

  /// 是否已加载配置
  bool get isLoaded => _config != null;

  /// 加载配置
  Future<AppConfig> loadConfig() async {
    try {
      log.i('开始加载应用配置', source: 'ConfigService');

      // 首先尝试从本地文件加载
      final localConfig = await _loadLocalConfigFile();
      if (localConfig != null) {
        _config = localConfig;
        log.i('从本地文件加载配置成功', source: 'ConfigService');
        return _config!;
      }

      // 如果本地文件不存在，从默认配置加载
      final defaultConfig = await _loadDefaultConfig();
      _config = defaultConfig;

      // 保存到本地文件
      await _saveLocalConfigFile(defaultConfig);

      log.i('从默认配置加载成功', source: 'ConfigService');
      return _config!;
    } catch (e, st) {
      log.e('加载配置失败，使用默认配置', source: 'ConfigService', error: e, stackTrace: st);
      _config = const AppConfig();
      return _config!;
    }
  }

  /// 从默认配置文件加载
  Future<AppConfig> _loadDefaultConfig() async {
    try {
      final configString = await rootBundle.loadString('assets/config/app_config.yaml');
      final yaml = loadYaml(configString) as YamlMap;
      return AppConfig.fromYaml(yaml);
    } catch (e) {
      log.w('加载默认配置文件失败，使用硬编码默认值: $e', source: 'ConfigService');
      return const AppConfig();
    }
  }

  /// 从本地文件加载配置
  Future<AppConfig?> _loadLocalConfigFile() async {
    try {
      if (_configFilePath == null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        _configFilePath = path.join(appDocDir.path, 'app_config.yaml');
      }

      final file = File(_configFilePath!);
      if (!await file.exists()) {
        return null;
      }

      final configString = await file.readAsString();
      final yaml = loadYaml(configString) as YamlMap;
      return AppConfig.fromYaml(yaml);
    } catch (e) {
      log.w('加载本地配置文件失败: $e', source: 'ConfigService');
      return null;
    }
  }

  /// 保存配置到本地文件
  Future<void> _saveLocalConfigFile(AppConfig config) async {
    try {
      if (_configFilePath == null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        _configFilePath = path.join(appDocDir.path, 'app_config.yaml');
      }

      final file = File(_configFilePath!);
      await file.writeAsString(config.toYamlString());
      log.i('配置文件保存成功: $_configFilePath', source: 'ConfigService');
    } catch (e, st) {
      log.e('保存配置文件失败', source: 'ConfigService', error: e, stackTrace: st);
    }
  }

  /// 更新配置
  Future<void> updateConfig(AppConfig newConfig) async {
    _config = newConfig;
    await _saveLocalConfigFile(newConfig);
    log.i('配置已更新', source: 'ConfigService');
  }

  /// 从服务器更新配置（在应用更新时调用）
  Future<bool> updateConfigFromServer(String serverConfigUrl) async {
    try {
      log.i('从服务器更新配置: $serverConfigUrl', source: 'ConfigService');

      // TODO: 实现从服务器下载配置的逻辑
      // 这里可以使用 Dio 或其他 HTTP 客户端下载新的配置文件
      // 下载后验证格式，然后保存到本地

      log.w('从服务器更新配置功能尚未实现', source: 'ConfigService');
      return false;
    } catch (e, st) {
      log.e('从服务器更新配置失败', source: 'ConfigService', error: e, stackTrace: st);
      return false;
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    final defaultConfig = await _loadDefaultConfig();
    await updateConfig(defaultConfig);
    log.i('配置已重置为默认值', source: 'ConfigService');
  }

  /// 获取配置文件路径
  String? get configFilePath => _configFilePath;
}
