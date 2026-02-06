#!/usr/bin/env python3
"""
VaultSafe 同步服务器 - FastAPI 版本
简单的 FastAPI 服务器，用于存储和检索加密的密码备份
支持多配置文件，通过 URL 参数指定配置名称
"""

import json
import os
import re
import shutil
from datetime import datetime
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBasic, HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import ORJSONResponse
from pydantic import BaseModel
import uvicorn


# 配置模型
class SyncUploadData(BaseModel):
    """同步上传数据模型"""
    device_id: str
    timestamp: int
    encrypted_data: str
    version: str = "1.0"


class ConfigResponse(BaseModel):
    """配置响应模型"""
    name: str
    last_updated: Optional[str] = None
    has_data: bool = False
    devices: List[str] = []
    backup: Dict[str, Any] = {}
    error: Optional[str] = None


class StatusResponse(BaseModel):
    """状态响应模型"""
    status: str
    data_dir: str
    total_configs: int
    configs: List[ConfigResponse]


# 配置
DEFAULT_CONFIG = 'default'
PORT = 5000
API_TOKEN: Optional[str] = None  # 设置为 None 则不需要认证
BASIC_AUTH_USERNAME: Optional[str] = None
BASIC_AUTH_PASSWORD: Optional[str] = None
DATA_DIR = 'sync_data'  # 数据目录

# 安全认证
security_bearer = HTTPBearer(auto_error=False)
security_basic = HTTPBasic(auto_error=False)


# 数据存储类
class DataStore:
    """数据存储管理类"""

    def __init__(self, data_dir: str):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)

    def get_config_file(self, config_name: str) -> str:
        """获取配置文件路径"""
        # 安全检查：只允许文件名（字母、数字、下划线、连字符）
        if not re.match(r'^[a-zA-Z0-9_-]+$', config_name):
            raise ValueError(f"Invalid config name: {config_name}")

        return os.path.join(self.data_dir, f"{config_name}.json")

    def load_data(self, config_name: str) -> Dict[str, Any]:
        """加载存储的数据"""
        data_file = self.get_config_file(config_name)

        if not os.path.exists(data_file):
            return {
                'config_name': config_name,
                'encrypted_data': None,
                'last_updated': None,
                'device_info': {}
            }

        try:
            with open(data_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {
                'config_name': config_name,
                'encrypted_data': None,
                'last_updated': None,
                'device_info': {}
            }

    def save_data(self, config_name: str, data: Dict[str, Any]) -> None:
        """保存数据到文件"""
        data_file = self.get_config_file(config_name)
        data['last_updated'] = datetime.now().isoformat()
        data['config_name'] = config_name

        with open(data_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    def clear_config(self, config_name: str) -> None:
        """清除指定配置的数据"""
        data_file = self.get_config_file(config_name)
        if os.path.exists(data_file):
            os.remove(data_file)

    def clear_all(self) -> None:
        """清除所有配置数据"""
        if os.path.exists(self.data_dir):
            shutil.rmtree(self.data_dir)
        os.makedirs(self.data_dir)

    def list_configs(self) -> List[str]:
        """列出所有配置文件"""
        if not os.path.exists(self.data_dir):
            return []

        configs = []
        for filename in os.listdir(self.data_dir):
            if filename.endswith('.json'):
                configs.append(filename[:-5])  # 移除 .json 后缀
        return configs


# 创建数据存储实例
data_store = DataStore(DATA_DIR)


# 依赖项：认证检查
async def verify_auth(
    bearer_credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_bearer),
    basic_credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_basic)
) -> None:
    """认证检查依赖项"""

    # 检查 Bearer Token
    if API_TOKEN:
        if bearer_credentials and bearer_credentials.credentials == API_TOKEN:
            return

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Bearer Token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 检查 Basic Auth
    if BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD:
        if (basic_credentials and
            basic_credentials.username == BASIC_AUTH_USERNAME and
            basic_credentials.password == BASIC_AUTH_PASSWORD):
            return

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Basic"},
        )


# 应用生命周期管理
@asynccontextmanager
async def lifespan(_app: FastAPI):
    """应用生命周期管理"""
    print(f"\n📁 数据目录: {os.path.abspath(DATA_DIR)}")
    print(f"🌐 同步端点: http://localhost:{PORT}/sync/<配置名>")
    print(f"📊 状态查询: http://localhost:{PORT}/status")
    print(f"📚 API 文档: http://localhost:{PORT}/docs")

    if API_TOKEN:
        print(f"🔐 Bearer Token: {API_TOKEN[:10]}...")
    elif BASIC_AUTH_USERNAME:
        print(f"🔑 Basic Auth: {BASIC_AUTH_USERNAME}:*****")
    else:
        print("⚠️  警告: 未启用认证，任何人都可以访问数据！")

    print("\n启动服务器...\n")
    yield
    print("\n服务器已关闭")


# 创建 FastAPI 应用
app = FastAPI(
    title="VaultSafe Sync Server",
    description="VaultSafe 密码管理器同步服务器 - 支持多配置文件存储",
    version="1.0.0",
    lifespan=lifespan
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 路由：同步端点
@app.post("/sync/{config_name}")
@app.get("/sync/{config_name}")
async def sync(
    config_name: str,
    request: Request,
    upload_data: Optional[SyncUploadData] = None,
    _: None = Depends(verify_auth)
):
    """
    同步端点 - 支持 GET 和 POST

    - **POST**: 上传加密数据
    - **GET**: 下载加密数据
    """

    try:
        # 验证配置名称
        data_store.get_config_file(config_name)

        if request.method == "POST":
            # 上传数据
            if not upload_data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No data provided"
                )

            if not upload_data.encrypted_data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="encrypted_data is required"
                )

            # 加载现有数据
            data = data_store.load_data(config_name)

            # 更新加密数据
            data['encrypted_data'] = upload_data.encrypted_data

            # 更新设备信息
            if upload_data.device_id:
                data['device_info'][upload_data.device_id] = {
                    'last_upload': datetime.now().isoformat(),
                    'timestamp': upload_data.timestamp,
                    'version': upload_data.version
                }

            # 保存数据
            data_store.save_data(config_name, data)

            # 日志输出
            try:
                backup = json.loads(upload_data.encrypted_data)
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已更新")
                print(f"  配置名称: {config_name}")
                print(f"  数据文件: {data_store.get_config_file(config_name)}")
                print(f"  设备ID: {upload_data.device_id}")
                print(f"  备份版本: {backup.get('version', 'N/A')}")
                print(f"  导出时间: {backup.get('exportedAt', 'N/A')}")
            except:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已更新")
                print(f"  配置名称: {config_name}")
                print(f"  数据文件: {data_store.get_config_file(config_name)}")
                print(f"  设备ID: {upload_data.device_id}")

            return {
                'status': 'success',
                'config_name': config_name,
                'message': 'Data uploaded successfully',
                'stored_at': data['last_updated']
            }

        else:  # GET
            # 下载数据
            data = data_store.load_data(config_name)

            if data['encrypted_data'] is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f'No backup has been uploaded for config "{config_name}" yet'
                )

            # 日志输出
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已下载")
            print(f"  配置名称: {config_name}")
            print(f"  最后更新: {data['last_updated']}")

            try:
                backup = json.loads(data['encrypted_data'])
                print(f"  备份版本: {backup.get('version', 'N/A')}")
                print(f"  导出时间: {backup.get('exportedAt', 'N/A')}")
            except:
                pass

            # 返回完整的备份数据
            return ORJSONResponse(content=json.loads(data['encrypted_data']))

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"同步失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# 路由：状态查询
@app.get("/status", response_model=StatusResponse)
async def get_status():
    """
    获取服务器状态

    返回所有配置文件的信息，包括：
    - 配置名称
    - 最后更新时间
    - 是否有数据
    - 设备列表
    - 备份信息
    """

    configs = []
    config_names = data_store.list_configs()

    for config_name in config_names:
        config_file = data_store.get_config_file(config_name)
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                config_data = json.load(f)

            has_data = config_data.get('encrypted_data') is not None
            backup_info = {}

            if has_data:
                try:
                    backup = json.loads(config_data['encrypted_data'])
                    backup_info = {
                        'version': backup.get('version'),
                        'exportedAt': backup.get('exportedAt'),
                        'checksum': backup.get('checksum', '')[:16] + '...'
                    }
                except:
                    pass

            configs.append(ConfigResponse(
                name=config_name,
                last_updated=config_data.get('last_updated'),
                has_data=has_data,
                devices=list(config_data.get('device_info', {}).keys()),
                backup=backup_info
            ))
        except Exception as e:
            configs.append(ConfigResponse(
                name=config_name,
                error=f'Unable to read: {str(e)}'
            ))

    return StatusResponse(
        status="running",
        data_dir=os.path.abspath(DATA_DIR),
        total_configs=len(configs),
        configs=configs
    )


# 路由：清除指定配置
@app.post("/clear/{config_name}")
async def clear_config(
    config_name: str,
    _: None = Depends(verify_auth)
):
    """
    清除指定配置的数据
    """

    try:
        data_store.clear_config(config_name)

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 配置已清除: {config_name}")

        return {
            'status': 'success',
            'config_name': config_name,
            'message': f'Config "{config_name}" has been cleared'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# 路由：清除所有配置
@app.post("/clear")
async def clear_all(
    _: None = Depends(verify_auth)
):
    """
    清除所有配置数据
    """

    try:
        data_store.clear_all()

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 所有配置已清除")

        return {
            'status': 'success',
            'message': 'All configs have been cleared'
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# 路由：健康检查
@app.get("/health")
async def health_check():
    """
    健康检查端点
    """
    return {"status": "healthy", "service": "vaultsafe-sync-server"}


def print_banner():
    """打印启动横幅"""
    banner = """
╔══════════════════════════════════════════════════════════╗
║            VaultSafe 同步服务器 (FastAPI)               ║
║                                                            ║
║  多配置支持 - 不同配置名称对应不同的数据文件            ║
║                                                            ║
╚══════════════════════════════════════════════════════════╝
    """
    print(banner)


if __name__ == '__main__':
    # 从环境变量读取配置（可选）
    API_TOKEN = os.getenv('VAULTSAFE_API_TOKEN', API_TOKEN)
    BASIC_AUTH_USERNAME = os.getenv('VAULTSAFE_USERNAME', BASIC_AUTH_USERNAME)
    BASIC_AUTH_PASSWORD = os.getenv('VAULTSAFE_PASSWORD', BASIC_AUTH_PASSWORD)
    PORT = int(os.getenv('VAULTSAFE_PORT', PORT))
    DATA_DIR = os.getenv('VAULTSAFE_DATA_DIR', DATA_DIR)

    # 更新数据存储实例
    data_store = DataStore(DATA_DIR)

    print_banner()

    # 启动服务器
    uvicorn.run(
        "sync_server:app",
        host="0.0.0.0",
        port=PORT,
        reload=False,
        access_log=False
    )
