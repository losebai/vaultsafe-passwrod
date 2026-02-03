#!/usr/bin/env python3
"""
VaultSafe 同步服务器
简单的 Flask 服务器，用于存储和检索加密的密码备份
"""

import json
import os
import base64
from datetime import datetime
from functools import wraps
from flask import Flask, request, jsonify, Response, abort
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # 启用跨域支持

# 配置
DATA_FILE = 'vaultsafe_sync.json'
PORT = 5000
API_TOKEN = None  # 设置为 None 则不需要认证
BASIC_AUTH_USERNAME = None
BASIC_AUTH_PASSWORD = None


def load_data():
    """加载存储的数据"""
    if not os.path.exists(DATA_FILE):
        return {
            'data': {
                'nonce': None,
                'encrypted_data': None,
                'version': None,
                'exportedAt': None,
                'checksum': None
            },
            'last_updated': None,
            'device_info': {}
        }

    try:
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {
            'data': {
                'nonce': None,
                'encrypted_data': None,
                'version': None,
                'exportedAt': None,
                'checksum': None
            },
            'last_updated': None,
            'device_info': {}
        }


def save_data(data):
    """保存数据到文件"""
    data['last_updated'] = datetime.now().isoformat()
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
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
    """解析加密的备份数据"""
    try:
        backup = json.loads(encrypted_json)

        # 提取核心数据
        if 'data' in backup and 'encrypted' in backup['data']:
            return {
                'nonce': backup.get('device_id'),
                'encrypted': backup['encrypted'],
                'version': backup.get('version'),
                'exportedAt': backup.get('exportedAt'),
                'checksum': backup.get('checksum'),
                'data': backup['data']
            }
        return backup
    except json.JSONDecodeError:
        return encrypted_json


@app.route('/sync', methods=['GET', 'POST'])
@check_auth
def sync():
    """同步端点 - 支持 GET 和 POST"""

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

            # 解析备份数据
            parsed_data = parse_backup_data(encrypted_data)

            # 加载现有数据
            data = load_data()

            # 更新数据
            data['data'] = parsed_data
            data['data']['nonce'] = device_id
            data['data']['version'] = version

            # 更新设备信息
            if device_id:
                data['device_info'][device_id] = {
                    'last_upload': datetime.now().isoformat(),
                    'timestamp': timestamp
                }

            # 保存数据
            save_data(data)

            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已更新")
            print(f"  设备ID: {device_id}")
            print(f"  版本: {version}")
            print(f"  时间戳: {timestamp}")

            return jsonify({
                'status': 'success',
                'message': 'Data uploaded successfully',
                'stored_at': data['last_updated']
            }), 200

        except Exception as e:
            print(f"上传失败: {e}")
            return jsonify({'error': str(e)}), 500

    else:  # GET
        # 下载数据
        try:
            data = load_data()

            if data['data']['nonce'] is None:
                return jsonify({
                    'error': 'No data available',
                    'message': 'No backup has been uploaded yet'
                }), 404

            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已下载")
            print(f"  最后更新: {data['last_updated']}")
            print(f"  版本: {data['data'].get('version', 'N/A')}")

            # 返回完整的备份数据结构
            response_data = {
                'data': {
                    'nonce': data['data']['nonce'],
                    'encrypted': data['data'].get('encrypted', False),
                    'version': data['data'].get('version'),
                    'exportedAt': data['data'].get('exportedAt'),
                    'checksum': data['data'].get('checksum')
                }
            }

            # 如果有完整的 data 字段，也返回
            if 'data' in data['data'] and isinstance(data['data']['data'], dict):
                response_data['data'].update(data['data']['data'])

            return jsonify(response_data), 200

        except Exception as e:
            print(f"下载失败: {e}")
            return jsonify({'error': str(e)}), 500


@app.route('/status', methods=['GET'])
def status():
    """获取服务器状态"""
    data = load_data()

    return jsonify({
        'status': 'running',
        'has_data': data['data']['nonce'] is not None,
        'last_updated': data['last_updated'],
        'devices': list(data['device_info'].keys()) if data['device_info'] else [],
        'data_file': os.path.abspath(DATA_FILE)
    })


@app.route('/clear', methods=['POST'])
@check_auth
def clear_data():
    """清除所有数据"""
    try:
        if os.path.exists(DATA_FILE):
            os.remove(DATA_FILE)

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 数据已清除")

        return jsonify({
            'status': 'success',
            'message': 'All data has been cleared'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def print_banner():
    """打印启动横幅"""
    banner = """
╔══════════════════════════════════════════════════════════╗
║            VaultSafe 同步服务器                          ║
║                                                            ║
║  一个简单的 Flask 服务器，用于存储加密的密码备份        ║
║                                                            ║
╚══════════════════════════════════════════════════════════╝
    """
    print(banner)
    print(f"📁 数据文件: {os.path.abspath(DATA_FILE)}")
    print(f"🌐 服务地址: http://localhost:{PORT}/sync")
    print(f"📊 状态查询: http://localhost:{PORT}/status")

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
    DATA_FILE = os.getenv('VAULTSAFE_DATA_FILE', DATA_FILE)

    print_banner()

    # 启动服务器
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=False
    )
