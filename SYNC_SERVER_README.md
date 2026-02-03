# VaultSafe 同步服务器配置

## 安装依赖

```bash
pip install flask flask-cors
```

## 配置选项

可以通过环境变量配置服务器：

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `VAULTSAFE_PORT` | 服务端口 | `5000` |
| `VAULTSAFE_DATA_FILE` | 数据文件路径 | `vaultsafe_sync.json` |
| `VAULTSAFE_API_TOKEN` | Bearer Token（可选） | `None` |
| `VAULTSAFE_USERNAME` | Basic Auth 用户名（可选） | `None` |
| `VAULTSAFE_PASSWORD` | Basic Auth 密码（可选） | `None` |

## 启动服务器

### 方式一：直接启动（无认证）
```bash
python sync_server.py
```

### 方式二：使用 Bearer Token
```bash
export VAULTSAFE_API_TOKEN="your-secret-token-here"
python sync_server.py
```

### 方式三：使用 Basic Auth
```bash
export VAULTSAFE_USERNAME="admin"
export VAULTSAFE_PASSWORD="your-password"
python sync_server.py
```

### 方式四：自定义端口和数据文件
```bash
export VAULTSAFE_PORT=8080
export VAULTSAFE_DATA_FILE="my_backup.json"
python sync_server.py
```

## Windows 命令提示符设置环境变量
```cmd
set VAULTSAFE_API_TOKEN=your-secret-token-here
python sync_server.py
```

## Windows PowerShell 设置环境变量
```powershell
$env:VAULTSAFE_API_TOKEN="your-secret-token-here"
python sync_server.py
```

## API 端点

### POST /sync
上传加密数据到服务器

**请求体：**
```json
{
  "device_id": "unique-device-id",
  "timestamp": 1234567890,
  "encrypted_data": "{\"version\":\"1.0\",...}",
  "version": "1.0"
}
```

### GET /sync
从服务器下载加密数据

**响应体：**
```json
{
  "data": {
    "nonce": "device-id",
    "encrypted": true,
    "version": "1.0",
    "exportedAt": "2024-01-01T00:00:00.000Z",
    "checksum": "sha256-hash"
  }
}
```

### GET /status
获取服务器状态

**响应体：**
```json
{
  "status": "running",
  "has_data": true,
  "last_updated": "2024-01-01T00:00:00.000Z",
  "devices": ["device-id-1", "device-id-2"],
  "data_file": "/path/to/vaultsafe_sync.json"
}
```

### POST /clear
清除所有数据（需要认证）

## 在 VaultSafe 中配置同步服务器

服务器地址格式：`http://localhost:5000/sync`

如果使用 Bearer Token，在认证方式中选择 "Bearer Token"，然后输入 Token。

如果使用 Basic Auth，在认证方式中选择 "Basic Auth"，然后输入用户名和密码。

## 安全建议

1. **生产环境务必启用认证**（Bearer Token 或 Basic Auth）
2. 使用 HTTPS（需要配置反向代理如 nginx）
3. 定期备份数据文件
4. 设置防火墙规则限制访问
