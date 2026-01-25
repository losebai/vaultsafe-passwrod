# 🔒 VaultSafe — 全端加密密码管理器

> **安全 · 隐私 · 跨平台 · 端到端加密**

VaultSafe 是一款开源、安全、跨平台的密码管理工具，采用 **本地密钥加密** 所有敏感数据。所有密码、分组、配置信息均在设备端使用用户主密钥加密，**服务器无法解密任何数据**。支持完全离线使用，联网仅用于加密后的数据同步。

---

## ✨ 核心特性

- 🔐 **端到端加密（E2EE）**：所有数据使用 PBKDF2-HMAC-SHA256 + AES-256-GCM 在本地加密
- 🌐 **跨平台**：一套代码构建 iOS、Android、Web、Windows、macOS、Linux 应用
- 📦 **密码管理**：
  - 增删改查密码条目
  - 复制用户名和密码到剪贴板
  - 安全显示/隐藏密码
  - 密码生成器工具（可用于 UI 集成）
- 🗂️ **分组管理**：将密码组织到分组/文件夹中
- ⚙️ **设置中心**：
  - 修改主密码（带密码强度验证）
  - 启用/禁用同步
  - 导入/导出加密备份（JSON 格式）
  - 自动锁定时间配置
  - 自定义数据存储目录
  - 生物识别开关（UI 已就绪，集成进行中）
- 🔄 **第三方同步（基础）**：
  - 配置自定义同步端点
  - 多种认证方式（Bearer Token、Basic Auth、自定义 Header）
  - 手动触发同步
  - 连接测试
- 🛡️ **零知识架构**：服务器仅存储加密数据，无法访问明文
- 💾 **数据持久化**：基于 Hive 的加密本地存储，应用重启后自动恢复

---

## 🛠 技术栈

- **框架**：Flutter 3.24+（Dart 3.5+）
- **状态管理**：Riverpod + StateNotifier
- **本地存储**：Hive（加密模式）
- **加密库**：`pointycastle` + `crypto`（PBKDF2 + AES-256-GCM）
- **网络同步**：`dio` + 自定义同步协议
- **安全存储**：`flutter_secure_storage`
- **文件选择**：`file_picker` 用于备份导入/导出
- **生物识别**：`local_auth`（Face ID / Touch ID / Windows Hello）
- **UI 组件**：Material 3 设计系统

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
│   ├── passwords/        # 密码管理 UI & 逻辑
│   ├── profile/          # 个人中心
│   ├── settings/         # 设置中心（密码、同步、备份）
│   └── home/             # 主界面（带导航）
├── shared/
│   ├── models/           # 数据模型（PasswordEntry、PasswordGroup、Settings）
│   ├── providers/        # Riverpod 提供者（auth、passwords、settings）
│   ├── utils/            # 工具类（密码生成器等）
│   └── platform/         # 平台特定服务
└── components/           # 可复用的 UI 组件
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

### 运行（不同平台）

```bash
# 移动端
flutter run -d android
flutter run -d ios

# Web
flutter run -d chrome --web-renderer html

# 桌面
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### 构建发布版

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web

# 桌面
flutter build windows
flutter build macos
flutter build linux
```

---

## 🔑 加密设计

### 主密钥生成

1. 用户设置 **主密码**（最少 8 个字符）
2. 使用 **PBKDF2-HMAC-SHA256** 派生密钥（100,000 次迭代）
3. 生成 **32 字节（256 位）主密钥**
4. 主密钥**永不离开设备**
5. 随机盐值生成并安全存储

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

## 🏗️ 开发状态

### ✅ 已实现功能

- [x] 主密码设置和认证
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

### 🚧 开发中

- [ ] 生物识别认证集成
- [ ] 自动同步定时器实现
- [ ] 密码强度指示器
- [ ] 密码生成器 UI 集成

### 📋 计划功能

- [ ] 设备列表管理
- [ ] 安全事件日志
- [ ] 主题切换（暗色/亮色）
- [ ] 拖拽分组重排序
- [ ] 多级文件夹层次结构
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
- **Hive 加密盒子**：用于密码和分组
- **Flutter Secure Storage**：用于同步令牌和设备 ID

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

- **"StorageService not initialized"**：重启应用
- **"Directory not writable"**：检查应用权限或选择不同的目录
- **同步失败**：使用同步设置中的"测试连接"按钮

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

---

## 📞 支持

- **问题**：在 GitHub Issues 上报告 Bug 和功能请求
- **文档**：查看 `CLAUDE.md` 获取详细的中文文档

---

> **VaultSafe — 你的密码，只属于你。**
> 始于 2026 年，为隐私而生。
