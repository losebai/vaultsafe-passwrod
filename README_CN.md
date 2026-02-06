# 🔒 VaultSafe — 全端加密密码管理器

> **安全 · 隐私 · 跨平台 · 端到端加密**

[![Version](https://img.shields.io/badge/version-1.0.1-blue)](https://github.com/yourusername/vaultsafe/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

VaultSafe 是一款开源、安全、跨平台的密码管理工具，采用 **本地密钥加密** 所有敏感数据。所有密码、分组、配置信息均在设备端使用用户主密钥加密，**服务器无法解密任何数据**。支持完全离线使用，联网仅用于加密后的数据同步。

**当前版本**: 1.0.1 | [更新日志](CHANGELOG.md)

---

## ✨ 核心特性

### 🔐 安全加密
- **端到端加密（E2EE）**：所有数据使用 PBKDF2-HMAC-SHA256 + AES-256-GCM 在本地加密
- **零知识架构**：服务器仅存储加密数据，无法访问明文
- **主密码保护**：最少 8 个字符，支持强度验证
- **安全存储**：基于 Hive 的加密本地存储，支持 Android Keystore / iOS Keychain
- **密码验证** (v1.0.1)：查看、复制、编辑密码需要主密码验证
- **可配置验证超时** (v1.0.1)：支持 10秒/30秒/1分钟/5分钟/15分钟

### 🌐 跨平台支持
- **移动端**：iOS、Android
- **桌面端**：Windows、macOS、Linux
- **一套代码**：Flutter 3.24+ 统一构建

### 📦 密码管理
- 增删改查密码条目
- 分组/文件夹管理
- 复制用户名和密码到剪贴板
- 安全显示/隐藏密码
- 密码强度检测
- 密码生成器工具
- 密码条目搜索功能
- **操作前密码验证** (v1.0.1)：查看、复制、编辑前需要验证

### ⚡ 性能优化 (v1.0.1)
- **异步密钥派生**：使用 Dart Isolate 在后台线程执行 PBKDF2
- **UI 流畅无卡顿**：100,000 次迭代不再阻塞主线程
- **快速响应**：解锁时加载指示器动画流畅

### ⚙️ 设置中心
- 修改主密码（带密码强度验证）
- 自动锁定时间配置（30秒/1分钟/5分钟/15分钟）
- 自定义数据存储目录
- 生物识别认证（指纹/Face ID/Windows Hello）
- 主题颜色自定义（8种预设颜色）
- 同步开关配置
- **密码验证超时配置** (v1.0.1)

### 🔄 数据同步
- 配置自定义同步端点
- 多种认证方式（Bearer Token、Basic Auth、自定义 Header）
- 手动触发同步
- 连接测试功能
- 冲突自动解决（基于时间戳）

### 💾 备份与恢复
- 导出加密备份（JSON 格式）
- 导入备份恢复数据
- 备份信息预览（版本、大小、日期）
- 自动备份管理（保留最近5个）
- 备份文件加密保护

### 📊 其他功能
- 系统日志查看（运行日志、错误日志）
- 版本信息显示
- 应用内更新检查（桌面端支持自动更新）
- 用户操作日志记录
- 响应式 Material 3 设计

### 📁 统一数据存储 (v1.0.1)
- **所有应用数据集中存储**：配置、数据库、日志统一在 `vault_safe_data/` 目录
- **自动配置迁移**：应用启动时自动从旧位置迁移配置文件
- **简化备份**：只需复制一个文件夹即可备份所有数据
- **跨平台一致性**：所有平台使用统一的目录结构

---

## 🛠 技术栈

### 核心框架
- **Flutter 3.24+**（Dart 3.5+）
- **Riverpod 2.5.1** - 状态管理
- **Material 3** - UI 设计系统

### 数据存储
- **Hive 2.2.3** - 本地 NoSQL 数据库（加密模式）
- **flutter_secure_storage 9.2.2** - 安全存储（密钥、令牌）
- **shared_preferences 2.3.2** - 轻量级配置存储
- **path_provider 2.1.3** - 文件路径获取

### 安全加密
- **pointycastle 3.9.1** - 加密算法库
- **crypto 3.0.3** - 哈希函数
- **PBKDF2-HMAC-SHA256** - 密钥派生（100,000 次迭代）
- **AES-256-GCM** - 对称加密
- **Dart Isolates** (v1.0.1) - 异步密钥派生，避免 UI 阻塞

### 网络通信
- **dio 5.7.0** - HTTP 客户端
- **connectivity_plus 6.0.5** - 网络状态检测

### UI 组件
- **phosphor_flutter 2.1.0** - 图标库
- **google_fonts 6.2.1** - 字体
- **flutter_svg 2.0.10** - SVG 图片支持

### 工具库
- **uuid 4.4.2** - UUID 生成
- **intl 0.19.0** - 国际化
- **file_picker 8.1.2** - 文件选择
- **local_auth 2.3.0** - 生物识别
- **package_info_plus 8.0.0** - 应用信息获取
- **yaml 3.1.2** - YAML 配置文件解析
- **open_filex 4.5.0** - 文件打开

---

## 📂 项目结构

```
lib/
├── main.dart                      # 应用入口
├── core/
│   ├── config/                    # 应用配置管理
│   │   └── app_config.dart       # 配置类（支持YAML）
│   ├── encryption/               # 加密核心
│   │   ├── encryption_service.dart
│   │   └── key_derivation.dart
│   ├── sync/                     # 同步引擎
│   │   ├── sync_service.dart
│   │   ├── sync_config.dart
│   │   └── sync_auth_type.dart
│   ├── backup/                   # 备份服务
│   │   └── backup_service.dart
│   ├── storage/                  # 存储服务
│   │   └── storage_service.dart
│   ├── update/                   # 更新管理
│   │   └── update_service.dart
│   ├── logging/                  # 日志系统
│   │   └── log_service.dart
│   └── auth/                     # 认证服务
│       └── auth_service.dart
├── features/
│   ├── auth/                     # 认证相关
│   │   ├── setup_screen.dart    # 首次设置
│   │   └── unlock_screen.dart   # 解锁界面
│   ├── passwords/                # 密码管理
│   │   ├── home_screen.dart     # 主页
│   │   ├── password_form_screen.dart
│   │   ├── group_form_screen.dart
│   │   └── password_detail_screen.dart
│   ├── settings/                 # 设置中心
│   │   └── settings_screen.dart
│   ├── update/                   # 更新界面
│   │   └── update_screen.dart
│   └── logs/                     # 日志查看
│       └── logs_screen.dart
├── shared/
│   ├── models/                   # 数据模型
│   │   ├── password_entry.dart
│   │   ├── password_group.dart
│   │   └── settings.dart
│   └── providers/                # Riverpod 提供者
│       ├── auth_provider.dart
│       ├── password_provider.dart
│       └── settings_provider.dart
└── components/                   # 可复用 UI 组件
```

---

## 🚀 快速开始

### 前置要求

- **Flutter SDK**: 3.24 或更高版本
- **Dart SDK**: 3.5 或更高版本
- **开发工具**:
  - Android Studio / VS Code（移动端开发）
  - Xcode（iOS 开发，仅 macOS）
  - Visual Studio（Windows 桌面开发）

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/vaultsafe.git
cd vaultsafe

# 2. 安装依赖
flutter pub get

# 3. 检查环境
flutter doctor

# 4. 运行应用
# 移动端
flutter run -d android
flutter run -d ios

# 桌面端
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

---

## 📦 打包发布指南

### 打包前准备

```bash
# 1. 清理构建缓存
flutter clean

# 2. 获取最新依赖
flutter pub get

# 3. 检查环境配置
flutter doctor -v

# 4. 更新版本号（在 pubspec.yaml 中）
# version: 1.0.1+2  # 版本号+构建号
```

### 🤖 Android 打包

#### APK 打包（调试/测试）

```bash
# 调试版 APK
flutter build apk --debug

# 发布版 APK
flutter build apk --release

# 分架构打包（生成更小的APK文件）
flutter build apk --split-per-abi --release
```

**输出位置**: `build/app/outputs/flutter-apk/`

#### AAB 打包（Google Play 上架）

```bash
# App Bundle（推荐用于 Play Store）
flutter build appbundle --release
```

**输出位置**: `build/app/outputs/bundle/release/`

#### Android 签名配置

创建 `android/key.properties` 文件（不要提交到 Git）：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=你的密钥别名
storeFile=/path/to/your/keystore.jks
```

修改 `android/app/build.gradle`：

```groovy
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### 代码混淆（可选）

```bash
flutter build apk --obfuscate --split-debug-info=./debug-info --release
```

#### 生成密钥库

```bash
keytool -genkey -v -keystore ~/vaultsafe-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vaultsafe
```

---

### 🍎 iOS 打包

```bash
# 1. 安装 CocoaPods 依赖
cd ios
pod install
cd ..

# 2. 构建 iOS 应用（需要 macOS 和 Xcode）
flutter build ios --release

# 3. 使用 Xcode 进行归档
open ios/Runner.xcworkspace
```

**在 Xcode 中**：
1. 选择 **Product** > **Archive**
2. 等待归档完成后，在 Organizer 中选择分发的方式：
   - **App Store Connect**：上传到 App Store
   - **Ad Hoc**：企业分发
   - **Enterprise**：企业内部分发
   - **Development**：开发测试

**输出位置**: `build/ios/archive/`

#### iOS 配置文件

在 `ios/Runner/Info.plist` 中配置权限和设置：

```xml
<key>NSFaceIDUsageDescription</key>
<string>使用 Face ID 进行身份验证</string>
<key>NSFaceIDUsageDescription</key>
<string>使用 Touch ID 进行身份验证</string>
```

---

### 🖥️ 桌面端打包

#### Windows

```bash
# Windows 发布版
flutter build windows --release

# 输出位置: build/windows/x64/runner/Release/
# 可执行文件: build/windows/x64/runner/Release/vaultsafe.exe
```

**打包为安装程序**（可选）：
使用工具如 [Inno Setup](https://jrsoftware.org/isinfo.php) 或 [NSIS](https://nsis.sourceforge.net/) 创建安装程序。

#### macOS

```bash
# macOS 发布版
flutter build macos --release

# 输出位置: build/macos/Build/Products/Release/
# 应用程序: build/macos/Build/Products/Release/vaultsafe.app
```

**创建 DMG 安装包**（可选）：
```bash
# 使用 create-dmg 工具
brew install create-dmg
create-dmg --volname "VaultSafe" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  "VaultSafe-Installer.dmg" \
  "build/macos/Build/Products/Release/vaultsafe.app"
```

#### Linux

```bash
# Linux 发布版
flutter build linux --release

# 输出位置: build/linux/x64/release/bundle/
```

**创建 AppImage 或 Deb 包**（可选）：
使用 [AppImageLauncher](https://github.com/AppImage/AppImageLauncher) 或其他打包工具。

---

### 🌐 Web 打包

```bash
# Web 发布版
flutter build web --release

# 输出位置: build/web/
```

**部署到静态网站托管**：
- GitHub Pages
- Netlify
- Vercel
- Firebase Hosting

---

### ⚙️ 打包配置优化

#### 1. 应用图标

**Android**:
将图标放到 `android/app/src/main/res/mipmap-*` 目录

**iOS**:
在 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 中替换图标

**桌面端**:
使用 [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) 包自动生成

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  windows:
    generate: true
    image_path: "assets/icons/app_icon.png"
  macos:
    generate: true
    image_path: "assets/icons/app_icon.png"
```

#### 2. 应用名称

修改各平台配置文件中的应用显示名称

#### 3. 版本号

在 `pubspec.yaml` 中修改：
```yaml
version: 1.0.1+2  # 格式: 版本号+构建号
```

#### 4. 权限配置

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSFaceIDUsageDescription</key>
<string>使用 Face ID 进行身份验证</string>
```

#### 5. 压缩优化

```bash
# 启用树摇（移除未使用的资源）
flutter build apk --release --tree-shake-icons

# 减小 APK 大小
flutter build apk --split-per-abi --release
```

---

### 🔐 发布版检查清单

- [ ] 更新版本号（`pubspec.yaml`）
- [ ] 配置应用图标和名称
- [ ] 配置签名（Android/iOS）
- [ ] 检查权限配置
- [ ] 测试所有核心功能
- [ ] 启用代码混淆（可选）
- [ ] 配置 ProGuard（Android）
- [ ] 移除调试日志
- [ ] 更新配置文件（`app_config.yaml`）
- [ ] 生成备份并测试恢复功能
- [ ] 测试更新功能（桌面端）

---

## 🔑 加密设计

### 主密钥生成流程

1. 用户设置 **主密码**（最少 8 个字符）
2. 使用 **PBKDF2-HMAC-SHA256** 派生密钥（100,000 次迭代）
3. 生成 **32 字节（256 位）主密钥**
4. 主密钥**永不离开设备**
5. 随机盐值生成并安全存储

### 数据加密流程

- 每个密码条目使用 **AES-256-GCM** 加密（带认证）
- 每次加密生成随机 **12 字节 nonce**
- 加密结构：
  ```json
  {
    "nonce": "base64...",
    "ciphertext": "base64...",
    "tag": "base64..."
  }
  ```
- 所有数据 Base64 编码后存储

### 存储架构

- **Hive** 加密盒子用于本地数据持久化
- 自动数据目录初始化
- 写入权限验证
- 应用重启后自动恢复
- 支持自定义数据目录路径

---

## 🔄 同步配置（第三方 API）

VaultSafe 支持将加密数据同步到您自己的服务器。所有同步数据均为 **AES-256-GCM 加密后的密文**，第三方服务无法读取内容。

### 支持的认证方式

| 方式 | 说明 |
|------|------|
| **Bearer Token** | JWT 或 API Token 放在 Authorization 头 |
| **Basic Auth** | 用户名和密码认证 |
| **自定义 Header** | 自定义 HTTP 头（如 `X-API-Key`） |

### 同步协议（REST API）

您的同步服务器需要实现这两个端点：

#### 上传加密数据（POST）

```http
POST /api/v1/sync
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_id": "uuid-string",
  "timestamp": 1705742400,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}

响应：
{
  "success": true,
  "message": "Data uploaded successfully"
}
```

#### 下载加密数据（GET）

```http
GET /api/v1/sync
Authorization: Bearer <token>

200响应：
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}
```

> **注意**：服务器只需存储/返回 `encrypted_data` 字段。VaultSafe 会通过保留最新时间戳来处理冲突解决。

---

## 📦 备份与恢复

### 导出备份

1. 进入 **设置** > **导出备份**
2. 备份将使用您的主密码加密
3. 文件保存到设备的下载文件夹（或平台特定位置）
4. 文件名格式：`vaultsafe_backup_YYYY-MM-DDTHH-MM-SS.json`

### 导入备份

1. 进入 **设置** > **导入备份**
2. 选择您的备份文件（.json）
3. 预览备份信息（版本、加密状态、大小、日期）
4. 确认导入以恢复数据

> ⚠️ **警告**：导入备份将覆盖现有数据。请先导出当前数据作为备份！

---

## ⚙️ 配置文件

VaultSafe 支持 YAML 配置文件，可在 `assets/config/app_config.yaml` 中自定义：

```yaml
# 应用信息
app:
  name: "VaultSafe"
  version: "1.0.1"

# API 配置
api:
  update_server: "https://api.yourserver.com/v1/update"
  sync:
    default_endpoint: "https://api.yourserver.com/api/v1/sync"
    timeout: 30

# 安全配置
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

# 功能开关
features:
  biometric_enabled: true
  sync_enabled: true
  auto_backup_enabled: true
  auto_backup_interval: 24
```

配置加载顺序：
1. 本地配置文件（`~/app_config.yaml`）
2. 默认配置文件（`assets/config/app_config.yaml`）
3. 硬编码默认值

---

## 🏗️ 开发状态

**当前版本**: **1.0.1** (2025-02-05)

### ✅ 已实现功能 (v1.0.1)

- [x] 主密码设置和认证
- [x] **异步密钥派生** (UI 永不卡顿) (v1.0.1)
- [x] **密码验证** (查看、复制、编辑前需验证) (v1.0.1)
- [x] **可配置验证超时** (v1.0.1)
- [x] 密码增删改查操作
- [x] 分组/文件夹管理
- [x] 加密本地存储（Hive）
- [x] 导入/导出加密备份
- [x] 修改主密码
- [x] 自动锁定超时设置
- [x] 第三方同步配置
- [x] 密码生成器工具
- [x] 自定义数据目录选择
- [x] 详细的调试日志
- [x] 系统日志查看
- [x] 版本信息显示
- [x] 生物识别认证
- [x] 主题颜色自定义
- [x] 密码条目搜索
- [x] 用户操作日志
- [x] 应用内更新检查
- [x] 同步开关配置
- [x] YAML 配置文件支持
- [x] **统一数据目录结构** (v1.0.1)
- [x] **自动配置迁移** (v1.0.1)
- [x] **改进的错误处理** (v1.0.1)
- [x] **友好的错误消息** (v1.0.1)

### 🚧 开发中

- [ ] 自动同步定时器实现
- [ ] 密码强度指示器 UI
- [ ] 自动备份功能

### 📋 计划功能

- [ ] 设备列表管理
- [ ] 安全事件日志
- [ ] 主题切换（暗色/亮色模式）
- [ ] 拖拽分组重排序
- [ ] 多级文件夹层次结构
- [ ] 冲突检测与解决 UI
- [ ] 增量同步
- [ ] 自动填充集成（移动端）
- [ ] 防截屏保护
- [ ] 单元测试（加密、同步）
- [ ] 两步验证（2FA）
- [ ] 密码共享功能
- [ ] 密码过期提醒
- [ ] 数据导入导出（其他密码管理器）
- [ ] WebDAV/WebSocket 同步支持

---

## 🔒 安全架构

### 零知识证明

- **主密码**：永不存储或传输
- **加密密钥**：本地派生，永不离开设备
- **同步凭据**：使用主密钥加密后存储
- **服务器数据**：仅存储加密数据（AES-256-GCM）

### 安全存储

- **Android Keystore** / **iOS Keychain**：用于敏感数据
- **Hive 加密盒子**：用于密码和分组
- **Flutter Secure Storage**：用于同步令牌和设备 ID

### 安全最佳实践

1. **主密码强度**：至少 8 个字符，建议包含大小写字母、数字和符号
2. **定期备份**：使用导出备份功能定期备份加密数据
3. **启用生物识别**：在支持的设备上启用指纹/Face ID
4. **自动锁定**：设置合理的自动锁定时间
5. **安全网络**：仅通过 HTTPS 连接同步服务器
6. **验证服务器**：使用同步设置中的"测试连接"功能

---

## 🐛 故障排除

### 重启后数据不持久

如果您在应用重启后遇到数据丢失：

1. **检查日志** - 查找 `StorageService:` 调试消息，显示：
   - 数据目录路径
   - Hive 初始化状态
   - 加载的密码/分组数量

2. **验证目录权限** - 应用需要写入权限访问：
   - `getApplicationDocumentsDirectory()/vault_safe_data`（默认）
   - 自定义目录（如果已配置）

3. **定期导出备份** - 使用设置 > 导出备份创建加密备份

### 常见问题

| 问题 | 解决方案 |
|------|---------|
| **"StorageService not initialized"** | 重启应用 |
| **"Directory not writable"** | 检查应用权限或选择不同的目录 |
| **同步失败** | 使用同步设置中的"测试连接"按钮 |
| **生物识别不可用** | 检查设备是否支持生物识别功能 |
| **无法导入备份** | 确认备份文件格式正确且未损坏 |
| **应用闪退** | 查看系统日志，联系开发者 |

### 获取日志

1. 在应用中进入 **设置** > **系统日志**
2. 查看运行日志和错误信息
3. 可以复制日志用于问题报告

---

## 📜 许可证

本项目采用 **MIT License** 开源 - 详见 [LICENSE](LICENSE) 文件。

---

## 🙌 贡献

欢迎贡献！请确保：

1. 新功能不影响加密安全性
2. 代码遵循现有样式和模式
3. 敏感数据处理有适当文档
4. 为关键功能添加测试（加密、同步）
5. 提交前运行 `flutter analyze` 和 `flutter test`

### 贡献流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📞 支持

- **问题报告**：在 [GitHub Issues](https://github.com/yourusername/vaultsafe/issues) 上报告 Bug
- **功能请求**：在 [GitHub Discussions](https://github.com/yourusername/vaultsafe/discussions) 中讨论
- **文档**：查看 `docs/` 目录获取详细文档
- **安全问题**：请通过私有渠道报告安全问题

---

## 📋 更新日志

### [1.0.1] (2025-02-05)

**新增功能** ✨
- 密码验证功能：查看、复制、编辑密码前需要主密码验证
- 可配置验证超时：支持 10秒/30秒/1分钟/5分钟/15分钟
- 统一数据目录：所有应用数据集中在 `vault_safe_data/` 目录
- 自动配置迁移：应用启动时自动从旧位置迁移配置文件

**性能优化** ⚡
- 异步密钥派生：使用 Dart Isolate 在后台线程执行 PBKDF2
- UI 流畅无卡顿：100,000 次迭代不再阻塞主线程
- 加载指示器动画流畅：解锁体验更好

**问题修复** 🐛
- 改进更新服务错误处理
- 添加友好的错误消息
- 网络错误分类和提示

**技术改进** 🔧
- 密钥派生异步化
- 配置文件自动迁移
- 代码质量提升

### [1.0.0] (2025-01-XX)

**初始发布** 🎉
- 核心密码管理功能
- 端到端加密（PBKDF2 + AES-256-GCM）
- 第三方同步功能
- 生物识别认证
- 自动锁定
- 备份与恢复

---

> **VaultSafe — 你的密码，只属于你。**
> 始于 2025 年，为隐私而生。
>
> **当前版本**: v1.0.1 | [更新日志](CHANGELOG.md)
>
> [官方网站](https://vaultsafe.app) | [在线文档](https://docs.vaultsafe.app) | [下载应用](https://github.com/yourusername/vaultsafe/releases)
