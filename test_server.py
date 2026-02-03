#!/usr/bin/env python3
"""
VaultSafe 同步服务器测试脚本
用于验证服务器功能是否正常
"""

import requests
import json
import sys

# 默认配置
BASE_URL = "http://localhost:5000"
API_TOKEN = None  # 如果设置了Token，在这里填写
USERNAME = None   # 如果设置了Basic Auth，在这里填写
PASSWORD = None


def test_status():
    """测试状态接口"""
    print("\n📊 测试状态接口...")
    try:
        response = requests.get(f"{BASE_URL}/status")
        print(f"   状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   服务器状态: {data.get('status')}")
            print(f"   是否有数据: {data.get('has_data')}")
            print(f"   数据文件: {data.get('data_file')}")
            return True
        return False
    except Exception as e:
        print(f"   ❌ 失败: {e}")
        return False


def test_upload():
    """测试上传数据"""
    print("\n⬆️  测试上传数据...")

    # 构造测试数据
    test_data = {
        "device_id": "test-device-123",
        "timestamp": 1704067200,
        "encrypted_data": json.dumps({
            "version": "1.0",
            "format": "vaultsafe-encrypted",
            "encrypted": True,
            "data": {
                "nonce": "test-device-123",
                "iv": "test-iv",
                "ciphertext": "test-ciphertext"
            },
            "checksum": "test-checksum",
            "exportedAt": "2024-01-01T00:00:00.000Z"
        }),
        "version": "1.0"
    }

    headers = {"Content-Type": "application/json"}
    if API_TOKEN:
        headers["Authorization"] = f"Bearer {API_TOKEN}"

    auth = None
    if USERNAME and PASSWORD:
        auth = (USERNAME, PASSWORD)

    try:
        response = requests.post(
            f"{BASE_URL}/sync",
            json=test_data,
            headers=headers,
            auth=auth
        )
        print(f"   状态码: {response.status_code}")
        if response.status_code == 200:
            print(f"   ✅ 上传成功: {response.json().get('message')}")
            return True
        else:
            print(f"   ❌ 失败: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ 失败: {e}")
        return False


def test_download():
    """测试下载数据"""
    print("\n⬇️  测试下载数据...")

    headers = {}
    if API_TOKEN:
        headers["Authorization"] = f"Bearer {API_TOKEN}"

    auth = None
    if USERNAME and PASSWORD:
        auth = (USERNAME, PASSWORD)

    try:
        response = requests.get(
            f"{BASE_URL}/sync",
            headers=headers,
            auth=auth
        )
        print(f"   状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ 下载成功")
            print(f"   设备ID: {data.get('data', {}).get('nonce')}")
            print(f"   版本: {data.get('data', {}).get('version')}")
            return True
        elif response.status_code == 404:
            print("   ℹ️  服务器上没有数据")
            return True
        else:
            print(f"   ❌ 失败: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ 失败: {e}")
        return False


def main():
    print("=" * 50)
    print("  VaultSafe 同步服务器测试")
    print("=" * 50)
    print(f"\n🌐 服务器地址: {BASE_URL}")

    if API_TOKEN:
        print(f"🔑 Bearer Token: {API_TOKEN[:10]}...")
    elif USERNAME:
        print(f"🔑 Basic Auth: {USERNAME}:***")

    # 检查服务器是否运行
    try:
        requests.get(BASE_URL, timeout=2)
    except Exception as e:
        print(f"\n❌ 无法连接到服务器: {e}")
        print("\n请确保:")
        print("  1. 服务器正在运行 (python sync_server.py)")
        print(f"  2. 服务器地址正确: {BASE_URL}")
        sys.exit(1)

    # 运行测试
    results = []
    results.append(("状态检查", test_status()))
    results.append(("上传数据", test_upload()))
    results.append(("下载数据", test_download()))

    # 打印结果
    print("\n" + "=" * 50)
    print("  测试结果汇总")
    print("=" * 50)

    for name, success in results:
        status = "✅ 通过" if success else "❌ 失败"
        print(f"  {name}: {status}")

    all_passed = all(r[1] for r in results)
    print("\n" + "=" * 50)

    if all_passed:
        print("🎉 所有测试通过！服务器工作正常。")
        print("\n现在可以在 VaultSafe 中配置同步服务器:")
        print(f"  服务器地址: {BASE_URL}/sync")
    else:
        print("⚠️  部分测试失败，请检查服务器配置。")

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
