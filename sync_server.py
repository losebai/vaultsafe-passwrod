#!/usr/bin/env python3
"""
VaultSafe 同步服务器
简单的 Flask 服务器，用于存储和检索加密的密码备份
支持多配置文件，通过 URL 参数指定配置名称
"""

import json
import os
import re
from datetime import datetime
from functools import wraps
from flask import Flask, request, jsonify, Response
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # 启用跨域支持

# 配置
DEFAULT_CONFIG = 'default'
PORT = 5000
API_TOKEN = None  # 设置为 None 则不需要认证
BASIC_AUTH_USERNAME = None
BASIC_AUTH_PASSWORD = None
DATA_DIR = 'sync_data'  # 数据目录


def get_config_file(config_name):
    """获取配置文件路径"""
    # 安全检查：只允许文件名（字母、数字、下划线、连字符）
    if not re.match(r'^[a-zA-Z0-9_-]+$', config_name):
        raise ValueError(f"Invalid config name: {config_name}")

    # 确保数据目录存在
    os.makedirs(DATA_DIR, exist_ok=True)

    return os.path.join(DATA_DIR, f"{config_name}.json")


def load_data(config_name):
    """加载存储的数据"""
    data_file = get_config_file(config_name)

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


def save_data(config_name, data):
    """保存数据到文件"""
    data_file = get_config_file(config_name)
    data['last_updated'] = datetime.now().isoformat()
    data['config_name'] = config_name

    with open(data_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def check_auth(f):
    """认证检查装饰器"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization

        # 检查 Bearer Token
        if API_TOKEN:
            bearer_token = None
            if request.headers.get('Authorization'):
                try:
                    bearer_token = request.headers.get('Authorization').split(' ')[1]
                except IndexError:
                    pass

            if bearer_token != API_TOKEN:
                return Response('Unauthorized: Invalid Bearer Token', 401,
                              {'WWW-Authenticate': 'Bearer realm="Login required"'})

        # 检查 Basic Auth
        if BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD:
            if auth is None or auth.username != BASIC_AUTH_USERNAME or auth.password != BASIC_AUTH_PASSWORD:
                return Response('Unauthorized: Invalid credentials', 401,
                              {'WWW-Authenticate': 'Basic realm="Login required"'})

        return f(*args, **kwargs)
    return decorated


def parse_backup_data(encrypted_json):
    """解析加密的备份数据 - 直接返回原始JSON"""
    # 直接返回原始数据，不做任何转换
    return encrypted_json


@app.route('/sync/<config_name>', methods=['GET', 'POST'])
@check_auth
def sync(config_name):
    """同步端点 - 支持 GET 和 POST，config_name 为配置名称"""

    if request.method == 'POST':
        # 上传数据
        try:
            request_data = request.get_json()

            if not request_data:
                return jsonify({'error': 'No data provided'}), 400

            device_id = request_data.get('device_id')
            timestamp = request_data.get('timestamp')
            encrypted_data = request_data.get('encrypted_data')
            version = request_data.get('version', '1.0')

            if not encrypted_data:
                return jsonify({'error': 'encrypted_data is required'}), 400

            # 直接存储客户端发送的完整JSON数据
            data = load_data(config_name)

            # 更新加密数据
            data['encrypted_data'] = encrypted_data

            # 更新设备信息
            if device_id:
                data['device_info'][device_id] = {
                    'last_upload': datetime.now().isoformat(),
                    'timestamp': timestamp,
                    'version': version
                }

            # 保存数据
            save_data(config_name, data)

            # 解析数据以获取信息（仅用于日志）
            try:
                backup = json.loads(encrypted_data)
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已更新")
                print(f"  配置名称: {config_name}")
                print(f"  数据文件: {get_config_file(config_name)}")
                print(f"  设备ID: {device_id}")
                print(f"  备份版本: {backup.get('version', 'N/A')}")
                print(f"  导出时间: {backup.get('exportedAt', 'N/A')}")
            except:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已更新")
                print(f"  配置名称: {config_name}")
                print(f"  数据文件: {get_config_file(config_name)}")
                print(f"  设备ID: {device_id}")

            return jsonify({
                'status': 'success',
                'config_name': config_name,
                'message': 'Data uploaded successfully',
                'stored_at': data['last_updated']
            }), 200

        except ValueError as e:
            return jsonify({'error': str(e)}), 400
        except Exception as e:
            print(f"上传失败: {e}")
            return jsonify({'error': str(e)}), 500

    else:  # GET
        # 下载数据
        try:
            data = load_data(config_name)

            if data['encrypted_data'] is None:
                return jsonify({
                    'error': 'No data available',
                    'config_name': config_name,
                    'message': f'No backup has been uploaded for config "{config_name}" yet'
                }), 404

            # 直接返回存储的完整JSON字符串
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已下载")
            print(f"  配置名称: {config_name}")
            print(f"  最后更新: {data['last_updated']}")

            # 解析数据以获取信息（仅用于日志）
            try:
                backup = json.loads(data['encrypted_data'])
                print(f"  备份版本: {backup.get('version', 'N/A')}")
                print(f"  导出时间: {backup.get('exportedAt', 'N/A')}")
            except:
                pass

            # 返回完整的备份数据结构
            # 直接返回 JSON 字符串，客户端自己解析
            return json.loads(data['encrypted_data'])

        except ValueError as e:
            return jsonify({'error': str(e)}), 400
        except Exception as e:
            print(f"下载失败: {e}")
            return jsonify({'error': str(e)}), 500


@app.route('/status', methods=['GET'])
def status():
    """获取服务器状态"""
    # 列出所有配置文件
    configs = []
    if os.path.exists(DATA_DIR):
        for filename in os.listdir(DATA_DIR):
            if filename.endswith('.json'):
                config_name = filename[:-5]  # 移除 .json 后缀
                config_file = os.path.join(DATA_DIR, filename)
                try:
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config_data = json.load(f)

                    # 解析加密数据以获取信息
                    has_data = config_data.get('encrypted_data') is not None
                    backup_info = {}
                    if has_data:
                        try:
                            backup = json.loads(config_data['encrypted_data'])
                            backup_info = {
                                'version': backup.get('version'),
                                'exportedAt': backup.get('exportedAt'),
                                'checksum': backup.get('checksum', '')[:16] + '...'  # 显示前16个字符
                            }
                        except:
                            pass

                    configs.append({
                        'name': config_name,
                        'last_updated': config_data.get('last_updated'),
                        'has_data': has_data,
                        'devices': list(config_data.get('device_info', {}).keys()),
                        'backup': backup_info
                    })
                except Exception as e:
                    configs.append({
                        'name': config_name,
                        'error': f'Unable to read: {str(e)}'
                    })

    return jsonify({
        'status': 'running',
        'data_dir': os.path.abspath(DATA_DIR),
        'total_configs': len(configs),
        'configs': configs
    })


@app.route('/clear/<config_name>', methods=['POST'])
@check_auth
def clear_config(config_name):
    """清除指定配置的数据"""
    try:
        data_file = get_config_file(config_name)
        if os.path.exists(data_file):
            os.remove(data_file)

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 配置已清除: {config_name}")

        return jsonify({
            'status': 'success',
            'config_name': config_name,
            'message': f'Config "{config_name}" has been cleared'
        }), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/clear', methods=['POST'])
@check_auth
def clear_all():
    """清除所有配置数据"""
    try:
        if os.path.exists(DATA_DIR):
            import shutil
            shutil.rmtree(DATA_DIR)
            os.makedirs(DATA_DIR)

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 所有配置已清除")

        return jsonify({
            'status': 'success',
            'message': 'All configs have been cleared'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def print_banner():
    """打印启动横幅"""
    banner = """
╔══════════════════════════════════════════════════════════╗
║            VaultSafe 同步服务器                          ║
║                                                            ║
║  多配置支持 - 不同配置名称对应不同的数据文件            ║
║                                                            ║
╚══════════════════════════════════════════════════════════╝
    """
    print(banner)
    print(f"📁 数据目录: {os.path.abspath(DATA_DIR)}")
    print(f"🌐 同步端点: http://localhost:{PORT}/sync/<配置名>")
    print(f"   示例: http://localhost:{PORT}/sync/default")
    print(f"        http://localhost:{PORT}/sync/work")
    print(f"        http://localhost:{PORT}/sync/personal")
    print(f"📊 状态查询: http://localhost:{PORT}/status")
    print(f"🗑️  清除配置: POST http://localhost:{PORT}/clear/<配置名>")

    if API_TOKEN:
        print(f"🔐 Bearer Token: {API_TOKEN[:10]}...")
    elif BASIC_AUTH_USERNAME:
        print(f"🔑 Basic Auth: {BASIC_AUTH_USERNAME}:*****")
    else:
        print("⚠️  警告: 未启用认证，任何人都可以访问数据！")

    print("\n启动服务器...")


if __name__ == '__main__':
    # 从环境变量读取配置（可选）
    API_TOKEN = os.getenv('VAULTSAFE_API_TOKEN', API_TOKEN)
    BASIC_AUTH_USERNAME = os.getenv('VAULTSAFE_USERNAME', BASIC_AUTH_USERNAME)
    BASIC_AUTH_PASSWORD = os.getenv('VAULTSAFE_PASSWORD', BASIC_AUTH_PASSWORD)
    PORT = int(os.getenv('VAULTSAFE_PORT', PORT))
    DATA_DIR = os.getenv('VAULTSAFE_DATA_DIR', DATA_DIR)

    print_banner()

    # 启动服务器
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=False
    )
