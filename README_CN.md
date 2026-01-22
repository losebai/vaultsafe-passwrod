# 🔒 VaultSafe — 全端加密密码管理器

> **安全 · 隐私 · 跨平台 · 端到端加密**

VaultSafe 是一款开源、安全、跨平台的密码管理工具，采用 **本地密钥加密** 所有敏感数据，支持 **App（Flutter Mobile）、Web（Flutter Web）和桌面 GUI（Flutter Desktop）** 三端同步。所有密码、分组、配置信息均在设备端使用用户私钥加密，**服务器无法解密任何数据**。支持完全离线使用，联网仅用于加密后的数据同步。

---

## ✨ 核心特性

- 🔐 **全程端到端加密（E2EE）**：所有数据使用用户主密钥（由密码派生）在本地加密，传输与存储均为密文。
- 🌐 **三端统一**：一套代码构建 iOS、Android、Web、Windows、macOS、Linux 应用。
- 📦 **密码管理**：增删改查密码条目（支持网站、用户名、密码、备注、自定义字段）。
- 🗂️ **分组管理**：支持多级文件夹/标签分组，便于组织密码。
- 👤 **个人中心**：查看账户信息、设备列表、安全日志。
- ⚙️ **设置中心**：
  - 设置/修改主密码（重新派生密钥）
  - 控制联网开关（启用/禁用自动同步）
  - 导入/导出加密备份（JSON / CSV 加密格式）
  - 生物识别（Face ID / Touch ID / Windows Hello）快速解锁
  - 自动锁定时间设置
  - 可配置数据存储目录
- 🔄 **可控同步**：仅当用户开启"同步"时，加密数据才上传至云端；可随时关闭联网，完全离线使用。
- 🛡️ **零知识架构**：服务端仅存储加密 blob，无法访问明文内容。
- 💾 **数据持久化**：所有数据保存在用户指定的本地目录，支持自定义存储路径。

---

## 🔑 加密设计

### 主密钥生成
- 用户首次设置 **主密码（Master Password）**
- 使用 **PBKDF2 + HMAC-SHA256**（或 Argon2）从主密码派生 **32 字节主密钥（Master Key）**
- 主密钥 **永不离开设备**，仅用于加解密

### 数据加密
- 每个密码条目使用 **AES-256-GCM** 加密（带认证）
- 每次加密生成随机 **nonce（IV）**
- 加密前序列化为 JSON，加密后 Base64 编码存储
- 示例结构：
  ```json
  {
    "nonce": "base64...",
    "ciphertext": "base64...",
    "tag": "base64..."
  }
  ```

### 同步机制
- 所有数据加密后上传至 **用户自选云存储**（默认提供 VaultSafe 官方同步服务，支持 WebDAV / Dropbox / 自建服务器）
- 同步元数据（如更新时间戳）也加密存储
- 冲突解决：按时间戳自动合并，保留最新版本

---

## 📱 功能模块

| 模块 | 功能 |
|------|------|
| **密码管理** | 添加/编辑/删除密码条目，支持复制密码、生成强密码、自动填充（移动端） |
| **分组管理** | 创建/重命名/删除分组，拖拽调整层级，支持搜索过滤 |
| **个人中心** | 显示设备列表、上次同步时间、安全事件日志（如登录尝试） |
| **设置中心** | 主密码修改、同步开关、生物识别、自动锁定、备份/恢复、主题切换、数据存储目录 |
| **同步引擎** | 增量同步、冲突检测、断点续传、手动强制同步 |

---

## 🛠 技术栈

- **框架**：Flutter 3.24+（Dart 3.5+）
- **状态管理**：Riverpod + AsyncNotifier
- **本地存储**：Hive（加密模式）
- **加密库**：`pointycastle` + `crypto`
- **网络同步**：`dio` + 自定义同步协议（基于 REST / WebSocket）
- **UI 组件**：Material 3 + 自定义安全组件（防截屏、防录屏）
- **构建目标**：
  - Mobile: iOS / Android
  - Web: PWA 支持
  - Desktop: Windows / macOS / Linux

---

## 📂 项目结构（简化）

```bash
vaultsafe/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── encryption/       # 加密核心（密钥派生、AES-GCM）
│   │   ├── storage/          # 本地数据存储服务
│   │   ├── sync/             # 同步引擎
│   │   └── security/         # 安全策略（防截屏、自动锁）
│   ├── features/
│   │   ├── auth/             # 主密码验证、解锁流程
│   │   ├── passwords/        # 密码管理 UI & 逻辑
│   │   ├── groups/           # 分组管理
│   │   ├── profile/          # 个人中心
│   │   ├── home/             # 主界面（响应式导航）
│   │   └── settings/         # 设置中心
│   └── shared/               # 通用组件、模型、常量
├── assets/                   # 图标、本地化
├── pubspec.yaml
├── README.md                 # 英文文档
└── README_CN.md              # 中文文档（本文件）
```

---

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/yourname/vaultsafe.git
cd vaultsafe
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行（任一平台）
```bash
# 移动端
flutter run -d android
flutter run -d ios

# Web
flutter run -d chrome --web-renderer html

# 桌面
flutter run -d windows
flutter run -d macos
```

### 4. 构建发布
```bash
flutter build apk --release
flutter build ipa --release
flutter build web
flutter build windows
```

---

## 🔒 安全承诺

- **绝不收集用户数据**
- **源码完全开源**（MIT 许可证）
- **所有加密在客户端完成**
- **主密码不会被传输或存储**
- **数据完全由用户控制**，支持自定义存储目录

> 💡 建议：定期导出加密备份，并保存在安全位置。

---

## 🔄 数据存储

VaultSafe 支持自定义数据存储目录，您可以在 **设置 > 数据 > 数据存储目录** 中更改存储位置。

### 默认存储位置
- **Windows**: `C:\Users\{用户名}\Documents\vault_safe_data`
- **macOS**: `/Users/{用户名}/Documents/vault_safe_data`
- **Linux**: `/home/{用户名}/Documents/vault_safe_data`

### 更改存储目录
1. 打开设置
2. 点击"数据存储目录"
3. 输入新的目录路径（绝对路径）
4. 点击"更改目录"
5. 系统会自动迁移所有现有数据到新位置

> ⚠️ 注意：更改存储目录会自动迁移所有数据，请确保目标位置有足够的磁盘空间。

---

## 🔄 同步配置（支持第三方接口）

VaultSafe 支持通过 **用户自定义的第三方 API** 实现加密数据同步，无需依赖官方服务器。所有同步数据均为 **AES-256-GCM 加密后的密文**，第三方服务无法读取内容。

### 🔧 可配置项（位于「设置中心 > 同步设置」）

| 配置项 | 说明 |
|-------|------|
| **同步开关** | 全局启用/禁用同步（关闭后完全离线） |
| **同步端点（Endpoint URL）** | 例如：`https://your-server.com/api/v1/sync` |
| **认证方式** | 支持：• Bearer Token• Basic Auth（用户名+密码）• 自定义 Header（如 `X-API-Key`） |
| **Token / 凭据** | 用户输入的密钥（**本地加密存储**，不以明文保存） |
| **自动同步间隔** | 可选：关闭 / 每5分钟 / 每15分钟 / 每小时 |
| **手动同步按钮** | 立即触发一次上传/下载 |
| **最后同步时间** | 显示上次成功同步时间戳 |
| **同步日志** | 记录成功/失败事件（不包含敏感数据） |

### 📡 同步协议要求（第三方 API 需实现）

VaultSafe 与第三方服务通过 **简单 RESTful 接口** 通信，只需实现两个端点：

#### 1. **上传加密数据（PUT / POST）**
```http
POST /api/v1/sync
Authorization: Bearer <user_token>
Content-Type: application/json

{
  "device_id": "uuid-string",
  "timestamp": 1705742400,
  "encrypted_data": "base64(AES-GCM(...))",
  "version": "1.0"
}
```

#### 2. **下载最新数据（GET）**
```http
GET /api/v1/sync
Authorization: Bearer <user_token>

→ 响应：
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64(...)",
  "version": "1.0"
}
```

> ✅ **注意**：
> - 第三方服务只需存储/返回 `encrypted_data` 字段，**无需理解其内容**。
> - VaultSafe 会自动处理冲突（保留 `timestamp` 最新的版本）。
> - 所有请求使用 HTTPS，禁止 HTTP（开发模式除外）。

### 🔐 凭据安全存储

- 用户输入的 Token 或密码 **不会以明文形式保存**。
- 使用 **主密钥派生的子密钥** 对凭据进行二次加密后存入本地安全存储（如 Android Keystore / iOS Keychain / Desktop Encrypted File）。
- 即使设备被物理获取，也无法直接提取同步凭据。

### 🛠 示例：配置 WebDAV 同步

您可将 VaultSafe 数据同步到 **私有 WebDAV 服务器**（如 Nextcloud、NAS）：

- **Endpoint**: `https://nextcloud.example.com/remote.php/dav/files/user/vaultsafe.json`
- **Auth**: Basic Auth（填入 Nextcloud 账号密码）
- VaultSafe 会 PUT/GET 整个加密 JSON 文件

> 💡 提示：项目提供 **"同步测试"按钮**，可验证配置是否有效。

---

## 🎨 界面特性

- **响应式设计**：桌面端侧边栏导航，移动端底部导航
- **Material Design 3**：现代化 UI，圆角设计，优雅的动画效果
- **暗色模式**：自动跟随系统或手动切换
- **侧边栏收缩**：桌面端支持侧边栏收缩，仅显示图标
- **对话框设置**：所有设置项使用弹窗形式，操作更自然

---

## 📜 许可证

本项目采用 [MIT License](LICENSE) 开源。

---

## 🙌 贡献

欢迎提交 Issue 或 PR！请确保：
- 新功能不影响现有加密安全性
- 通过单元测试（`encryption_test.dart`, `sync_test.dart`）
- 遵循代码规范

---

> **VaultSafe — 你的密码，只属于你。**
> 项目始于 2026 年，为隐私而生。
