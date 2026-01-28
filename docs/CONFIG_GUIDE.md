# VaultSafe 配置系统使用指南

## 概述

VaultSafe 使用 YAML 配置文件管理系统，允许您灵活配置应用的各种参数，而无需修改代码。配置文件在应用启动时加载，并在应用更新时自动更新。

## 配置文件位置

- **默认配置**: `assets/config/app_config.yaml` (应用内置)
- **本地配置**: `{应用数据目录}/app_config.yaml` (运行时生成)
- **优先级**: 本地配置 > 默认配置

## 配置文件结构

### 应用信息 (app)
```yaml
app:
  name: "VaultSafe"
  version: "1.0.0"
  description: "安全的跨平台密码管理器"
```

### API 配置 (api)
```yaml
api:
  update_server: "https://api.yourserver.com/v1/update"
  sync:
    default_endpoint: "https://api.yourserver.com/api/v1/sync"
    timeout: 30
```

### 安全配置 (security)
```yaml
security:
  encryption_salt: "your-custom-salt-value"
  password_generator:
    default_length: 16
    include_uppercase: true
    include_lowercase: true
    include_numbers: true
    include_symbols: true
  password_requirements:
    min_length: 8
    require_uppercase: true
    require_lowercase: true
    require_numbers: true
    require_symbols: false
```

### 自动锁定 (auto_lock)
```yaml
auto_lock:
  default_timeout: 60  # 秒
  timeout_options: [30, 60, 300, 900]
```

### 同步配置 (sync)
```yaml
sync:
  default_interval: "none"  # none, 5, 15, 60 (分钟)
  max_retry_count: 3
  retry_delay: 1000  # 毫秒
```

### 备份配置 (backup)
```yaml
backup:
  max_backup_count: 5
  file_name_format: "vaultsafe_backup_{timestamp}.json"
```

### 日志配置 (logging)
```yaml
logging:
  level: "info"  # debug, info, warning, error
  max_file_size: 10  # MB
  max_file_count: 5
  file_name: "vaultsafe.log"
```

## 使用配置

### 在代码中使用

```dart
import 'package:vaultsafe/core/config/app_config.dart';

// 获取配置实例
final configService = ConfigService.instance;
final config = configService.config;

// 访问配置值
final updateUrl = config.updateServer;
final salt = config.encryptionSalt;
final timeout = config.syncTimeout;
```

### 动态更新配置

```dart
// 更新特定配置
final newConfig = config.copyWith(
  updateServer: 'https://new-api.example.com/v1/update',
  syncTimeout: 60,
);

await ConfigService.instance.updateConfig(newConfig);
```

### 重置为默认配置

```dart
await ConfigService.instance.resetToDefault();
```

## 配置自动更新

当应用检测到更新时，会自动执行以下操作：

1. **下载更新**: 从配置的服务器下载应用更新
2. **更新配置**: 在安装更新前，自动下载最新的配置文件
3. **应用新配置**: 重启应用后自动使用新配置

### 配置更新流程

```dart
final updater = ConfigUpdater();

// 方式1: 从服务器更新
final success = await updater.updateConfigFromServer(
  'https://your-server.com/config/app_config.yaml'
);

// 方式2: 下载配置文件但不应用
final filePath = await updater.downloadConfigFile(
  'https://your-server.com/config/app_config.yaml'
);

// 方式3: 从本地文件应用配置
await updater.applyConfigFromFile(filePath);
```

## 配置文件托管

### 服务器端配置

在您的更新服务器上，配置文件应该放在以下位置：

```
https://api.yourserver.com/v1/config/app_config.yaml
```

### 版本管理

配置文件中的版本号用于判断是否需要更新：

```yaml
app:
  version: "1.0.0"  # 每次配置修改时递增
```

### 安全建议

1. **加密敏感配置**: 对于包含敏感信息的配置，考虑加密存储
2. **环境变量**: 生产环境的密钥应使用环境变量
3. **访问控制**: 配置文件应该有适当的访问控制
4. **版本控制**: 使用版本控制管理配置文件的变更

## 常见配置场景

### 场景1: 更新服务器地址

```yaml
api:
  update_server: "https://your-production-server.com/v1/update"
```

### 场景2: 自定义加密盐值

```yaml
security:
  encryption_salt: "your-production-salt-value-here"
```

### 场景3: 调整密码强度要求

```yaml
security:
  password_requirements:
    min_length: 12
    require_symbols: true
```

### 场景4: 更改日志级别

```yaml
logging:
  level: "debug"  # 开发环境
  # level: "error"  # 生产环境
```

### 场景5: 自定义主题颜色

```yaml
ui:
  default_theme_color: 0xFF4CAF50  # 绿色主题
  theme_colors:
    - 0xFF4CAF50
    - 0xFF2196F3
    # ... 更多颜色
```

## 故障排查

### 配置未生效

1. 检查本地配置文件路径
2. 验证 YAML 格式是否正确
3. 查看日志获取详细错误信息

### 配置更新失败

1. 检查网络连接
2. 验证配置文件 URL 是否正确
3. 确认服务器返回的是有效的 YAML 格式

### 重置配置

如果配置出现问题，可以删除本地配置文件：

```bash
# Windows
del %APPDATA%\vault_safe_data\app_config.yaml

# macOS/Linux
rm ~/Library/Application\ Support/vault_safe_data/app_config.yaml
```

应用重启后会使用默认配置重新生成。

## 最佳实践

1. **版本控制**: 将默认配置文件纳入版本控制
2. **环境分离**: 为不同环境（开发、测试、生产）使用不同的配置
3. **文档化**: 在配置文件中添加注释说明各个配置项
4. **渐进式更新**: 配置更新应该向后兼容
5. **测试**: 在测试环境验证配置更改后再应用到生产环境
