# 🔒 VaultSafe — 全端加密密码管理器

> **安全 · 隐私 · 跨平台 · 端到端加密**

[![Version](https://img.shields.io/badge/version-1.0.1-blue)](https://github.com/yourusername/vaultsafe/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

VaultSafe 是一款开源、安全、跨平台的密码管理工具，采用 **本地密钥加密** 所有敏感数据。所有密码、分组、配置信息均在设备端使用用户主密钥加密，**服务器无法解密任何数据**。支持完全离线使用，联网仅用于加密后的数据同步。

**当前版本**: 1.0.1 | [更新日志](CHANGELOG.md)

## 📱 应用截图

### 移动端
<table>
  <tr>
    <td><img src="docs/app/home.png" alt="App 主页" width="200"/></td>
    <td><img src="docs/app/lock.png" alt="App 锁屏" width="200"/></td>
  </tr>
</table>

### PC 桌面
<table>
  <tr>
    <td><img src="docs/pc/设置.png" alt="设置" width="300"/></td>
    <td><img src="docs/pc/锁屏.png" alt="锁屏" width="300"/></td>
  </tr>
  <tr>
    <td><img src="docs/pc/同步.png" alt="同步" width="300"/></td>
    <td><img src="docs/pc/主页.png" alt="主页" width="300"/></td>
  </tr>
</table>

---

## ✨ 核心特性

- 🔐 **端到端加密（E2EE）**：所有数据使用 PBKDF2-HMAC-SHA256 + AES-256-GCM 在本地加密
- 🌐 **跨平台支持**：iOS、Android、Web、Windows、macOS、Linux 一套代码
- 📦 **密码管理**：
  - 增删改查密码条目
  - 复制用户名和密码到剪贴板
  - 安全显示/隐藏密码
  - **密码验证** (v1.0.1)：查看、复制、编辑密码需要主密码验证
  - **可配置验证超时** (v1.0.1)：支持 10秒/30秒/1分钟/5分钟/15分钟
  - 密码生成器工具
- 🗂️ **分组管理**：将密码组织到文件夹中
- ⚙️ **设置中心**：
  - 修改主密码（带密码强度验证）
  - 启用/禁用同步
  - 导入/导出加密备份（JSON 格式）
  - 自动锁定超时配置
  - 自定义数据目录选择
  - 生物识别认证开关（UI 就绪，集成进行中）
  - **密码验证超时配置** (v1.0.1)
- 🔄 **第三方同步**（基础）：
  - 配置自定义同步端点
  - 多种认证方式（Bearer Token、Basic Auth、自定义 Header）
  - 手动触发同步
  - 连接测试
- 🛡️ **零知识架构**：服务器仅存储加密数据，无法访问明文
- 💾 **数据持久化**：基于 Hive 的加密本地存储，应用重启后自动恢复
- ⚡️ **性能优化**：
  - **异步密钥派生** - UI 永不卡顿 (v1.0.1)
  - **100,000 次 PBKDF2 迭代**不阻塞主线程 (v1.0.1)
- 📁 **统一数据存储**：
  - **所有应用数据在一个目录**（`vault_safe_data/`）(v1.0.1)
  - **自动配置迁移**从旧版本 (v1.0.1)

---

## 🛠 技术栈

- **框架**：Flutter 3.24+（Dart 3.5+）
- **状态管理**：Riverpod（v2.5.1）+ StateNotifier
- **本地存储**：
  - **Hive**（v2.2.3）- 轻量级 NoSQL 数据库，用于加密数据存储
  - **Hive Flutter**（v1.1.0）- Hive 的 Flutter 集成
  - **flutter_secure_storage**（v9.2.2）- 敏感数据的安全存储（主密钥、令牌）
  - **shared_preferences**（v2.3.2）- 应用设置的简单键值对存储
  - **path_provider**（v2.1.3）- 跨平台文件系统路径
- **加密**：`pointycastle`（v3.9.1）+ `crypto`（v3.0.3）（PBKDF2 + AES-256-GCM）
- **并发**：Dart Isolates（用于 v1.0.1 的异步密钥派生）
- **网络**：`dio`（v5.7.0）+ 自定义同步协议
- **文件选择**：`file_picker`（v8.1.2）用于备份导入/导出
- **生物识别**：`local_auth`（v2.3.0）（Face ID / Touch ID / Windows Hello）
- **UI**：Material 3 设计系统

---

## 📂 项目结构

```
lib/
├── main.dart
├── core/
│   ├── encryption/       # 加密核心（密钥派生、AES-GCM）
│   ├── sync/             # 支持第三方 API 的同步引擎
│   ├── backup/           # 备份/恢复服务
│   ├── storage/          # 基于 Hive 的加密本地存储
│   └── security/         # 安全策略
├── features/
│   ├── auth/             # 主密码设置、认证、解锁流程
│   ├── passwords/        # 密码管理 UI 和逻辑
│   ├── profile/          # 个人资料页面
│   ├── settings/         # 设置中心（密码、同步、备份）
│   └── home/             # 带导航的主页
├── shared/
│   ├── models/           # 数据模型（PasswordEntry、PasswordGroup、Settings）
│   ├── providers/        # Riverpod 提供者（auth、passwords、settings）
│   ├── utils/            # 工具（密码生成器等）
│   └── platform/         # 平台特定服务
└── components/           # 可复用 UI 组件
```

---

## 🚀 快速开始

### 前置要求

- Flutter SDK 3.24 或更高版本
- Dart 3.5 或更高版本

### 安装依赖

```bash
flutter pub get
```

### 在不同平台运行

```bash
# 移动端
flutter run -d android
flutter run -d ios

# Web
flutter run -d chrome --web-renderer html

# 桌面端
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

---

## 🔐 加密设计

### 主密钥生成

1. 用户设置 **主密码**（最少 8 个字符）
2. 使用 **PBKDF2-HMAC-SHA256** 派生密钥，100,000 次迭代
3. 生成 **32 字节（256 位）主密钥**
4. 主密钥**永不离开设备**

### 数据加密

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

#### Hive NoSQL 数据库
VaultSafe 使用 **Hive** 作为主要的本地存储方案 - 一款快速、轻量级的键值数据库，为 Flutter 优化。

**数据组织（盒子）**：
```
vault_safe_data/
├── passwords.hive        # 加密的密码条目
├── groups.hive           # 加密的分组数据
├── settings.hive         # 应用设置
└── hive.lock             # 并发访问的文件锁
```

**关键特性**：
- **加密盒子**：Hive 中存储的所有数据都使用 AES-256-GCM 预加密
- **三个存储盒子**：
  - `passwords` - 存储所有密码条目（每个单独加密）
  - `groups` - 存储文件夹/分组组织
  - `settings` - 存储应用配置
- **自定义目录支持**：用户可以选择自定义存储位置
- **写入权限验证**：初始化前自动验证
- **自动恢复**：数据在应用重启后持久化
- **跨平台**：在 iOS、Android、Windows、macOS、Linux 上无缝工作

**默认存储路径**：
- **Windows**：`%APPDATA%\vault_safe_data`
- **macOS**：`~/Library/Application Support/vaultsafe_data`
- **Linux**：`~/.local/share/vaultsafe_data`
- **Android**：`/data/data/<user>/flutter.vaultsafe_data`
- **iOS**：`<AppHome>/Documents/vaultsafe_data`

#### 安全存储层

敏感信息使用平台特定的安全存储：

- **Android Keystore**：用于主密钥和同步令牌的硬件支持密钥存储
- **iOS Keychain**：敏感凭据的加密存储
- **Windows/Desktop**：基于文件的加密存储

**安全存储的内容**：
- 主密码派生的加密密钥
- 第三方同步认证令牌
- 同步的设备标识符
- 生物识别认证偏好

#### 简单配置存储

- **SharedPreferences**：轻量级键值存储，用于：
  - UI 偏好（主题、自动锁定超时）
  - 功能标志（启用生物识别、启用同步）
  - 最后同步时间戳
- - 用户偏好

### 数据流

1. **用户创建/编辑密码** → 使用 AES-256-GCM 加密 → 存储到 Hive `passwords` 盒子
2. **用户更改设置** → 更新 Hive `settings` 盒子（如果敏感）或 SharedPreferences（如果不敏感）
3. **收到同步令牌** → 使用主密钥加密 → 存储到 flutter_secure_storage
4. **应用重启** → Hive 初始化所有盒子 → 数据自动可用

---

## 🔄 同步配置（第三方 API）

VaultSafe 支持将加密数据同步到您自己的服务器。所有同步数据均为 **AES-256-GCM 加密后的密文**，第三方服务无法读取内容。

### 支持的认证方式

| 方式 | 说明 |
|--------|-------------|
| **Bearer Token** | JWT 或 API token 放在 Authorization 头 |
| **Basic Auth** | 用户名和密码认证 |
| **Custom Headers** | 自定义 HTTP 头（如 `X-API-Key`） |

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
```

#### 下载加密数据（GET）
```http
GET /api/v1/sync
Authorization: Bearer <token>

响应：
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}
```

> **注意**：服务器仅返回 `encrypted_data` 字段。VaultSafe 通过保留最新时间戳来处理冲突解决。

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

> ⚠️ **警告**：导入备份将覆盖现有数据。请先导出当前数据！

---

## 🏗️ 开发状态

**当前版本**：**1.0.1** (2025-02-05)

### ✅ 已实现功能 (v1.0.1)
- [x] 主密码设置和认证
- [x] **异步密钥派生**（UI 永不卡顿）
- [x] **密码验证**用于敏感操作（查看、复制、编辑）
- [x] **可配置验证超时**
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
- [x] **统一数据目录结构**
- [x] **自动配置迁移**
- [x] **改进的错误处理**用于更新服务
- [x] **友好的错误消息**用于网络问题

### 🚧 开发中
- [ ] 生物识别认证集成
- [ ] 自动同步定时器实现
- [ ] 密码强度指示器
- [ ] 密码生成器 UI 集成

### 📋 计划功能
- [ ] 设备列表管理
- [ ] 安全事件日志
- [ ] 主题切换（暗色/亮色模式）
- [ ] 拖拽分组重排序
- [ ] 冲突检测与解决
- [ ] 增量同步
- [ ] 自动填充集成（移动端）
- [ ] 防截屏保护
- [ ] 单元测试（加密、同步）
- [ ] Isar 数据库迁移（可选）

---

## 🔒 安全架构

### 零知识证明

- **主密码**：永不存储或传输
- **加密密钥**：本地派生，永不离开设备
- **同步凭据**：使用主密钥加密后存储
- **服务器数据**：仅存储加密数据（AES-256-GCM）

### 安全存储

- **Android Keystore** / **iOS Keychain**：用于敏感数据
- **Hive 加密盒子**：所有数据使用 AES-256-GCM 预加密
- **Flutter Secure Storage**：用于同步令牌和设备 ID

### 安全存储的内容

- 主密码派生的加密密钥
- 第三方同步认证令牌
- 同步的设备标识符
- 生物识别认证偏好

---

## 🐛 故障排除

### 重启后数据不持久

如果您在应用重启后遇到数据丢失：

1. **检查日志** - 查找 `StorageService:` 调试消息，显示：
   - 数据目录路径
   - Hive 初始化状态
   - 加载的密码/分组数量

2. **验证权限** - 应用需要写入权限访问：
   - `getApplicationDocumentsDirectory()/vault_safe_data`（默认）
   - 自定义目录（如果已配置）

3. **定期导出备份** - 使用设置 > 导出备份创建加密备份
   - 这可以防止数据丢失

### 常见问题

- **"StorageService not initialized"**：重启应用
- **"Directory not writable"**：检查应用权限或选择不同的目录
- **"Sync failing"**：使用同步设置中的"测试连接"按钮

---

## 📜 许可证

本项目采用 **MIT License** 开源 - 详见 [LICENSE](LICENSE) 文件。

---

## 🙌 贡献

欢迎贡献！请确保：
- 新功能不影响加密安全性
- 代码遵循现有样式和模式
- 敏感数据处理有适当文档
- 为关键功能添加测试（加密、同步）

### 📋 资源

- **问题**：在 GitHub Issues 上报告 Bug 和功能请求
- **文档**：查看 `CLAUDE.md` 获取详细中文文档
- **更新日志**：查看 [CHANGELOG.md](CHANGELOG.md) 获取版本历史和更新

---

## 📋 更新日志

### **[1.0.1]** (2025-02-05)
- ✨ 密码验证用于敏感操作（查看、复制、编辑）
- ⚡ 异步密钥派生（UI 永不卡顿）
- 📁 统一数据目录结构
- 🐛 改进错误处理
