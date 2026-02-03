# VaultSafe 打包与安装指南

本文档详细介绍如何在不同平台上打包、签名和分发 VaultSafe 密码管理器。

---

## 📋 目录

- [环境准备](#环境准备)
- [Windows 打包](#windows-打包)
- [macOS 打包](#macos-打包)
- [Linux 打包](#linux-打包)
- [Android 打包](#android-打包)
- [iOS 打包](#ios-打包)
- [Web 部署](#web-部署)
- [CI/CD 自动化](#cicd-自动化)
- [常见问题](#常见问题)

---

## 环境准备

### 1. Flutter SDK 安装

确保已安装 Flutter 3.24+：

```bash
flutter --version
# 输出应显示 Flutter 3.24.x 或更高版本
```

### 2. 平台特定工具

| 平台 | 必需工具 |
|------|---------|
| **Windows** | Visual Studio 2022 (C++ 桌面开发 workload) |
| **macOS** | Xcode 15+、CocoaPods |
| **Linux** | GCC、clang、ninja、pkg-config |
| **Android** | Android Studio、JDK 11+ |
| **iOS** | Xcode 15+、CocoaPods、Apple Developer 账号 |
| **Web** | Chrome/Edge (用于测试) |

### 3. 项目依赖

```bash
# 进入项目目录
cd vaultsafe-passwrod

# 获取依赖
flutter pub get

# 运行测试（确保代码正确）
flutter test
```

---

## Windows 打包

### 1. 构建 Release 版本

```bash
# 构建 Windows 可执行文件
flutter build windows --release

# 输出位置
# build\windows\x64\runner\Release\
```

### 2. 创建安装程序 (使用 Inno Setup)

#### 安装 Inno Setup

1. 下载 [Inno Setup](https://jrsoftware.org/isdl.php)
2. 安装到默认路径

#### 创建安装脚本

创建文件 `installer.iss`：

```iss
; VaultSafe 安装脚本
[Setup]
AppName=VaultSafe
AppVersion=1.0.0
DefaultDirName={autopf}\VaultSafe
DefaultGroupName=VaultSafe
OutputDir=installer-output
OutputBaseFilename=VaultSafe-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\VaultSafe"; Filename: "{app}\vaultsafe.exe"
Name: "{commondesktop}\VaultSafe"; Filename: "{app}\vaultsafe.exe"

[Run]
Filename: "{app}\vaultsafe.exe"; Description: "启动 VaultSafe"; Flags: nowait postinstall skipifsilent
```

#### 编译安装程序

```bash
# 使用 ISCC 编译器
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss

# 输出位置
# installer-output\VaultSafe-Setup.exe
```

### 3. 代码签名 (可选但推荐)

#### 获取代码签名证书

1. 从 CA (如 DigiCert, Sectigo) 购买代码签名证书
2. 导出为 .pfx 文件

#### 使用 SignTool 签名

```bash
# 设置证书路径
set CERT_FILE=path\to\certificate.pfx
set CERT_PASSWORD=your_password

# 签名可执行文件
"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign /f %CERT_FILE% /p %CERT_PASSWORD% /tr http://timestamp.digicert.com /td sha256 /fd sha256 "build\windows\x64\runner\Release\vaultsafe.exe"

# 签名安装程序
"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign /f %CERT_FILE% /p %CERT_PASSWORD% /tr http://timestamp.digicert.com /td sha256 /fd sha256 "installer-output\VaultSafe-Setup.exe"
```

### 4. 分发

- 直接分发 `vaultsafe.exe` (便携版)
- 或分发 `VaultSafe-Setup.exe` (安装版)

---

## macOS 打包

### 1. 构建 Release 版本

```bash
flutter build macos --release

# 输出位置
# build/macos/Build/Products/Release/vaultsafe.app
```

### 2. 创建 DMG 安装镜像

#### 安装 create-dmg 工具

```bash
# 使用 Homebrew 安装
brew install create-dmg
```

#### 创建 DMG

```bash
# 创建 DMG 镜像
create-dmg \
  --volname "VaultSafe" \
  --volicon "assets/app_icon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "vaultsafe.app" 175 120 \
  --hide-extension "vaultsafe.app" \
  --app-drop-link 425 120 \
  "VaultSafe-1.0.0.dmg" \
  "build/macos/Build/Products/Release/vaultsafe.app"
```

### 3. 代码签名和公证 (macOS 必需)

#### 设置签名身份

```bash
# 查看可用的签名身份
security find-identity -v -p codesigning

# 输出示例
# 1) 83AF8D7B0A1B2C3D4E5F6789ABCDEF0123456789 "Apple Development: your@email.com (TEAMID)"
#     (选择 Developer ID Application 证书)
```

#### 修改 macos/Podfile

```ruby
# 在 macos/Podfile 中添加
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))

  # 添加代码签名配置
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_ENTITLEMENTS'] = nil
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      end
    end
  end
end
```

#### 签名应用

```bash
# 设置签名身份
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"

# 签名 .app
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" \
  --entitlements "macos/Runner/Release.entitlements" \
  "build/macos/Build/Products/Release/vaultsafe.app"

# 验证签名
codesign --verify --verbose "build/macos/Build/Products/Release/vaultsafe.app"
```

#### 公证应用 (Notarization)

```bash
# 设置 Apple ID 和密码
export APPLE_ID="your@email.com"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # 从 appleid.apple.com 生成
export TEAM_ID="TEAMID"

# 公证应用
xcrun notarytool submit "VaultSafe-1.0.0.dmg" \
  --apple-id "$APPLE_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

# 订阅公证 ( staple ) 到 DMG
xcrun stapler staple "VaultSafe-1.0.0.dmg"
```

### 4. 分发

- 上传 `VaultSafe-1.0.0.dmg` 到网站
- 或发布到 GitHub Releases

---

## Linux 打包

### 1. 构建 Release 版本

```bash
flutter build linux --release

# 输出位置
# build/linux/x64/release/bundle/
```

### 2. 创建 AppImage (通用格式)

#### 安装 appimagetool

```bash
# 下载 appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
```

#### 创建 AppDir 结构

```bash
# 创建 AppDir
mkdir -p VaultSafe.AppDir/usr/bin
mkdir -p VaultSafe.AppDir/usr/share/applications
mkdir -p VaultSafe.AppDir/usr/share/icons/hicolor/256x256/apps

# 复制可执行文件
cp build/linux/x64/release/bundle/vaultsafe VaultSafe.AppDir/usr/bin/

# 创建 .desktop 文件
cat > VaultSafe.AppDir/vaultsafe.desktop <<EOF
[Desktop Entry]
Name=VaultSafe
Comment=安全的密码管理器
Exec=vaultsafe
Icon=vaultsafe
Type=Application
Categories=Utility;Security;
EOF

cp VaultSafe.AppDir/vaultsafe.desktop VaultSafe.AppDir/usr/share/applications/

# 复制图标
cp assets/app_icon.png VaultSafe.AppDir/vaultsafe.png
cp assets/app_icon.png VaultSafe.AppDir/usr/share/icons/hicolor/256x256/apps/vaultsafe.png

# 创建 AppRun
cat > VaultSafe.AppDir/AppRun <<EOF
#!/bin/bash
exec "\${APPDIR}/usr/bin/vaultsafe" "\$@"
EOF
chmod +x VaultSafe.AppDir/AppRun
```

#### 构建 AppImage

```bash
./appimagetool-x86_64.AppImage VaultSafe.AppDir VaultSafe-x86_64.AppImage

# 输出: VaultSafe-x86_64.AppImage
```

### 3. 创建 Debian 包 (.deb)

#### 安装依赖

```bash
sudo apt-get install dpkg-deb
```

#### 创建包结构

```bash
# 创建 debian 包目录
mkdir -p vaultsafe-debian/opt/vaultsafe
mkdir -p vaultsafe-debian/usr/share/applications
mkdir -p vaultsafe-debian/usr/share/icons/hicolor/256x256/apps
mkdir -p vaultsafe-debian/DEBIAN

# 复制文件
cp -r build/linux/x64/release/bundle/* vaultsafe-debian/opt/vaultsafe/

# 创建控制文件
cat > vaultsafe-debian/DEBIAN/control <<EOF
Package: vaultsafe
Version: 1.0.0
Architecture: amd64
Maintainer: Your Name <your@email.com>
Description: VaultSafe 密码管理器
 VaultSafe 是一款安全的跨平台密码管理工具。
Depends: libgtk-3-0, libkeyutils1
EOF

# 创建 postinst 脚本
cat > vaultsafe-debian/DEBIAN/postinst <<EOF
#!/bin/bash
chmod +x /opt/vaultsafe/vaultsafe
EOF
chmod +x vaultsafe-debian/DEBIAN/postinst
```

#### 构建 .deb

```bash
dpkg-deb --build vaultsafe-debian vaultsafe_1.0.0_amd64.deb
```

### 4. 分发

- AppImage: 通用 Linux 格式
- .deb: Debian/Ubuntu 系发行版
- .rpm: Fedora/RHEL 系发行版 (类似 .deb 流程)

---

## Android 打包

### 1. 创建 Keystore

```bash
# 创建 keystore 文件
keytool -genkey -v -keystore ~/vaultsafe-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias vaultsafe \
  -dname "CN=VaultSafe, OU=Development, O=YourCompany, L=YourCity, ST=YourState, C=CN"

# 将 keystore 复制到项目目录
# 创建 android/key.properties
```

### 2. 配置签名

创建 `android/key.properties`：

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=vaultsafe
storeFile=/path/to/vaultsafe-key.jks
```

修改 `android/app/build.gradle`：

```gradle
// 在文件开头添加
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

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
        }
    }
}
```

### 3. 构建 APK/AAB

```bash
# 构建 APK (用于直接安装)
flutter build apk --release

# 输出: build/app/outputs/flutter-apk/app-release.apk

# 构建 App Bundle (用于上传 Google Play)
flutter build appbundle --release

# 输出: build/app/outputs/bundle/release/app-release.aab
```

### 4. 上传到 Google Play

1. 创建 Google Play Console 开发者账号 ($25 一次性费用)
2. 创建新应用
3. 上传 `app-release.aab`
4. 填写商店信息、截图、隐私政策
5. 提交审核

### 5. 分发 APK

- GitHub Releases
- 官方网站
- 第三方应用商店 (如 F-Droid)

---

## iOS 打包

### 1. 配置签名

#### 注册 Apple Developer 账号

- 个人账号: $99/年
- 组织账号: $99/年

#### 配置 Xcode 项目

```bash
# 打开 Xcode 项目
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择 "Runner" target
2. "Signing & Capabilities" 标签
3. 选择 "Team"
4. 确保 "Automatically manage signing" 已勾选

### 2. 添加权限

修改 `ios/Runner/Info.plist`：

```xml
<key>NSFaceIDUsageDescription</key>
<string>使用 Face ID 快速解锁密码库</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问照片库以导入头像</string>

<key>NSCameraUsageDescription</key>
<string>需要使用相机扫描二维码</string>
```

### 3. 构建 Archive

```bash
# 构建 iOS Archive
flutter build ios --release

# 在 Xcode 中打开项目
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择 "Product" > "Archive"
2. Archive 构建完成后，点击 "Distribute App"
3. 选择分发方式

### 4. 发布到 App Store

#### TestFlight 测试

1. 在 Xcode 中选择 "TestFlight & App Store"
2. 上传到 App Store Connect
3. 在 App Store Connect 添加测试员
4. 测试员通过 TestFlight 安装

#### App Store 发布

1. 完成商店信息：
   - 应用名称
   - 副标题
   - 描述
   - 关键词
   - 截图 (各设备尺寸)
   - 隐私政策 URL
2. 提交审核
3. 等待审核通过 (通常 1-3 天)

### 5. 企业分发 (可选)

对于企业内部分发：

```bash
# 在 Xcode 中选择 "Ad Hoc" 或 "Enterprise" 分发
# 导出 IPA 文件

# 使用 HTTPS 服务器分发或使用第三方平台 (如 TestFlight 替代品)
```

---

## Web 部署

### 1. 构建 Web 应用

```bash
# 构建 Web 版本
flutter build web --release

# 输出位置
# build/web/
```

### 2. 部署到 Firebase Hosting

#### 安装 Firebase CLI

```bash
npm install -g firebase-tools
```

#### 初始化 Firebase 项目

```bash
firebase login
firebase init hosting
# 选择 build/web 作为公共目录
# 配置为单页应用
```

#### 部署

```bash
firebase deploy
```

### 3. 部署到 Netlify

```bash
# 安装 Netlify CLI
npm install -g netlify-cli

# 登录
netlify login

# 部署
netlify deploy --prod --dir=build/web
```

### 4. 部署到 GitHub Pages

```bash
# 安装 Flutter 部署工具
flutter pub global activate flutter_launcher_icons

# 构建并部署到 gh-pages 分支
flutter build web --release
cd build/web
git init
git checkout -b gh-pages
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

在 GitHub 仓库设置中：
1. Settings > Pages
2. Source 选择 `gh-pages` 分支
3. Save

### 5. 配置 PWA (可选)

创建 `web/manifest.json`：

```json
{
  "name": "VaultSafe",
  "short_name": "VaultSafe",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#6750A4",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## CI/CD 自动化

### 1. GitHub Actions 自动构建

创建 `.github/workflows/build.yml`：

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        include:
          - os: ubuntu-latest
            platform: linux
          - os: macos-latest
            platform: macos
          - os: windows-latest
            platform: windows

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build
        run: |
          if [ "${{ matrix.platform }}" == "linux" ]; then
            flutter build linux --release
          elif [ "${{ matrix.platform }}" == "macos" ]; then
            flutter build macos --release
          elif [ "${{ matrix.platform }}" == "windows" ]; then
            flutter build windows --release
          fi
        shell: bash

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: vaultsafe-${{ matrix.platform }}
          path: |
            build/linux/x64/release/bundle/
            build/macos/Build/Products/Release/
            build/windows/x64/runner/Release/
```

### 2. 自动发布到 GitHub Releases

```yaml
- name: Create Release
  uses: softprops/action-gh-release@v1
  with:
    files: |
      vaultsafe-*.zip
      vaultsafe-*.dmg
      vaultsafe-*.exe
    draft: false
    prerelease: false
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 常见问题

### Q1: Windows 构建失败，提示 MSVC not found

**解决方案**：
1. 安装 Visual Studio 2022
2. 在安装时选择 "使用 C++ 的桌面开发" workload
3. 重启电脑后重新构建

### Q2: macOS 代码签名失败

**解决方案**：
```bash
# 清理构建缓存
flutter clean
cd macos
rm -rf Pods Podfile.lock
pod install
cd ..
flutter build macos --release
```

### Q3: Android 构建时找不到 keystore

**解决方案**：
1. 确保 `android/key.properties` 文件存在
2. 检查文件中的路径是否正确
3. 不要将 `key.properties` 提交到 Git (添加到 .gitignore)

### Q4: iOS 构建失败，提示 Team 未设置

**解决方案**：
1. 在 Xcode 中打开 `ios/Runner.xcworkspace`
2. 选择 Runner > Signing & Capabilities
3. 选择正确的 Team
4. 重新构建

### Q5: Web 构建后在浏览器中无法运行

**解决方案**：
- 确保使用 `--release` 模式构建
- 检查浏览器控制台是否有错误
- 验证 web 服务器的 MIME 类型配置

### Q6: 如何减小应用体积

**Android/iOS**:
```bash
# 优化资源
flutter build apk --release --split-per-abi

# 或使用 ProGuard/R8 (android/app/build.gradle)
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

**Desktop**:
- 使用 UPX 压缩可执行文件
```bash
upx --best --lzma vaultsafe
```

---

## 📞 获取帮助

- **GitHub Issues**: [https://github.com/yourname/vaultsafe/issues](https://github.com/yourname/vaultsafe/issues)
- **文档**: 查看 [README_CN.md](README_CN.md)
- **Email**: support@vaultsafe.example.com

---

> **提示**: 首次打包建议先在测试环境中验证整个流程，确保所有步骤正常后再进行正式发布。
