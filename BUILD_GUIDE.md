# VaultSafe 构建指南

本文档说明如何为 Android、Web 和桌面（Windows/macOS/Linux）三端构建 VaultSafe。

## 前置要求

### 通用要求
- Flutter SDK 3.24+
- Dart 3.5+
- Git

### 平台特定要求

#### Android
- Android Studio
- JDK 8 或更高版本
- Android SDK (API 21+)

#### Web
- Chrome 浏览器（用于开发）
- 无需额外工具

#### Windows
- Visual Studio 2022（包含 C++ 桌面开发工具）
- Windows 10 或更高版本

#### macOS
- Xcode 14 或更高版本
- macOS 10.15 或更高版本
- CocoaPods

#### Linux
- Clang、CMake、Ninja、GTK3 开发库
```bash
sudo apt-get install clang cmake ninja-build libgtk-3-dev
```

## 快速开始

### 1. 克隆项目并安装依赖

```bash
cd vaultsafe
flutter pub get
```

### 2. 运行应用

#### Android
```bash
# 连接 Android 设备或启动模拟器
flutter run -d android
# 或
flutter run -d <device_id>
```

#### Web
```bash
flutter run -d chrome
# 或使用 HTML 渲染器（更好的兼容性）
flutter run -d chrome --web-renderer html
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

## 构建发布版本

### Android

#### APK（直接安装）
```bash
flutter build apk --release
```

输出位置：`build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle（用于 Google Play）
```bash
flutter build appbundle --release
```

输出位置：`build/app/outputs/bundle/release/app-release.aab`

### Web

```bash
# 构建 Web 应用
flutter build web

# 使用 HTML 渲染器（更好的兼容性）
flutter build web --web-renderer html

# 使用 CanvasKit（更好的性能）
flutter build web --web-renderer canvaskit
```

输出位置：`build/web/`

部署：
```bash
# 部署到任何静态网站托管服务
# 例如：Firebase Hosting, GitHub Pages, Netlify
cd build/web
firebase deploy  # 如果使用 Firebase Hosting
```

### Windows

```bash
flutter build windows --release
```

输出位置：`build\windows\runner\Release\`

打包为安装程序（需要 WiX Toolset 或 InnoSetup）：
```bash
# 使用 InnoSetup 创建安装程序
# 创建 .iss 文件并使用 InnoSetup 编译
```

### macOS

```bash
flutter build macos --release
```

输出位置：`build/macos/Build/Products/Release/`

创建 .dmg 安装包：
```bash
# 使用 create-dmg 或手动创建
hdiutil create -volname "VaultSafe" -srcfolder build/macos/Build/Products/Release -ov -format UDZO vaultsafe.dmg
```

### Linux

```bash
flutter build linux --release
```

输出位置：`build/linux/x64/release/bundle/`

创建 .deb 包：
```bash
# 使用 dpkg-deb
cd build/linux/x64/release/bundle/
mkdir -p vaultsafe/opt
cp -r * vaultsafe/opt/
mkdir -p vaultsafe/DEBIAN

# 创建 DEBIAN/control 文件
cat > vaultsafe/DEBIAN/control << EOF
Package: vaultsafe
Version: 1.0.0
Architecture: amd64
Maintainer: Your Name <email@example.com>
Description: VaultSafe Password Manager
 Secure, end-to-end encrypted password manager
EOF

dpkg-deb --build vaultsafe
```

## 代码混淆和优化

### Android（ProGuard）
已在 `android/app/build.gradle` 中配置 ProGuard：
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 所有平台
```bash
# 启用代码混淆（需要 obfuscate 配置）
flutter build <platform> --release --obfuscate --split-debug-info=./debug-info
```

## 安全注意事项

### 1. 签名

#### Android
在 `android/app/build.gradle` 中配置签名：
```gradle
android {
    signingConfigs {
        release {
            storeFile file("path/to/keystore.jks")
            storePassword "your-password"
            keyAlias "your-key-alias"
            keyPassword "your-key-password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### Windows/macOS
使用代码签名证书对应用进行签名以避免安全警告。

### 2. 权限最小化
应用已配置最小必要权限：
- Android: 仅网络、生物识别、网络状态
- iOS: 仅 Face ID/Touch ID
- 桌面: 无需特殊权限

### 3. 数据保护
- 所有数据使用 AES-256-GCM 加密
- 主密钥使用 PBKDF2 派生（100,000 次迭代）
- 敏感数据存储在安全存储中（Android Keystore、iOS Keychain）

## PWA 配置

Web 版本已配置为 PWA（渐进式 Web 应用）：

1. **manifest.json** - 定义应用元数据
2. **service_worker.js** - 离线支持
3. **图标** - 可安装到主屏幕

安装后可作为独立应用运行。

## 故障排除

### Android
- **构建失败**: 检查 Android SDK 路径
- **签名错误**: 确保 keystore 文件存在且密码正确

### Web
- **CORS 错误**: 配置服务器允许跨域请求
- **Service Worker 失败**: 检查 HTTPS 要求（localhost 除外）

### Desktop
- **Windows**: 安装 Visual Studio C++ 构建工具
- **macOS**: 安装 Xcode 命令行工具 `xcode-select --install`
- **Linux**: 安装 GTK3 开发库

## 版本发布

### 1. 更新版本号

编辑 `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

### 2. 构建所有平台
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# Web
flutter build web --web-renderer html

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 3. 测试
在真实设备上测试所有构建版本。

### 4. 发布
- Android: 上传到 Google Play
- Web: 部署到静态托管
- Desktop: 分发安装包

## 开发建议

### 热重载
开发时使用热重载提高效率：
```bash
flutter run
# 在代码更改后按 'r' 热重载，'R' 热重启
```

### 平台特定代码
使用条件导入和平台检查：
```dart
import 'dart:io' show Platform;

if (Platform.isAndroid) {
  // Android 特定代码
} else if (Platform.isIOS) {
  // iOS 特定代码
}
```

### 调试
```bash
# 查看详细日志
flutter run -v

# 性能分析
flutter run --profile
```

## 支持的平台特性

| 特性 | Android | iOS | Web | Windows | macOS | Linux |
|------|---------|-----|-----|---------|-------|-------|
| 生物识别 | ✅ | ✅ | ❌ | Windows Hello | Touch ID | ❌ |
| 截屏防护 | ✅ | ✅ | ❌ | ⚠️ | ✅ | ❌ |
| 安全存储 | ✅ Keystore | ✅ Keychain | ⚠️ Encrypted LS | DPAPI | Keychain | Secret Service |
| 离线使用 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 自动同步 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

✅ 完全支持
⚠️ 部分支持
❌ 不支持
