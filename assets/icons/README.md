# VaultSafe 应用图标

## 图标说明

本项目使用盾牌+锁风格的设计，体现安全、可靠的品牌形象。

### 设计元素
- **盾牌**: 象征保护和安全
- **锁**: 代表加密和数据保护
- **颜色**: 使用深蓝色渐变（#004878 到 #002d4d）
- **高光**: 金色锁体，突出重点

### 主题色
- 主色: `#004878` (RGB: 0, 72, 120)
- 深色: `#002d4d` (RGB: 0, 45, 77)
- 金色: `#ffd700` 到 `#ffaa00`

## 如何生成 PNG 图标

`flutter_launcher_icons` 需要 PNG 格式的图标文件。请使用以下任一方法将 SVG 转换为 PNG：

### 方法 1: 使用在线工具（推荐）

1. 访问 [CloudConvert SVG to PNG](https://cloudconvert.com/svg-to-png)
2. 上传 `app_icon.svg`
3. 设置输出尺寸为 **1024x1024** 像素
4. 下载并保存为 `app_icon.png` 到当前目录

### 方法 2: 使用 Figma（专业设计）

1. 在 Figma 中创建 1024x1024 的画板
2. 导入 `app_icon.svg`
3. 导出为 PNG (1024x1024)

### 方法 3: 使用命令行工具（开发者）

如果你安装了 Inkscape：

```bash
# Windows
inkscape app_icon.svg --export-type=png --export-filename=app_icon.png --export-width=1024 --export-height=1024

# macOS/Linux
inkscape app_icon.svg --export-type=png --export-filename=app_icon.png --export-width=1024 --export-height=1024
```

## 生成应用图标

在获取 `app_icon.png` 文件后，运行以下命令生成各平台图标：

```bash
# 1. 首先安装依赖（如果还没有安装）
flutter pub get

# 2. 生成图标
dart run flutter_launcher_icons
```

## 生成的图标位置

生成后，图标会被放置到以下位置：

- **Android**: `android/app/src/main/res/`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Windows**: `windows/runner/resources/`
- **macOS**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Linux**: `linux/`

## 在 Flutter 中使用图标

要在 Flutter 应用中使用 SVG 图标：

```dart
import 'package:flutter_svg/flutter_svg.dart';

// 使用图标
SvgPicture.asset(
  'assets/icons/app_icon.svg',
  width: 48,
  height: 48,
)
```

## 自定义图标

如需自定义图标设计，请编辑 `app_icon.svg` 文件，然后重新生成 PNG 并运行图标生成命令。
