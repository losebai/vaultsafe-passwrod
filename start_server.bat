@echo off
REM VaultSafe 同步服务器启动脚本
REM 使用方法：
REM   1. 无认证启动: start_server.bat
REM   2. 设置Token后启动: 修改下面的TOKEN变量，然后运行

chcp 65001 >nul
echo.
echo ========================================
echo   VaultSafe 同步服务器启动脚本
echo ========================================
echo.

REM ==================== 配置区域 ====================
REM 设置为空字符串表示不使用该认证方式

REM Bearer Token 认证
set TOKEN=

REM Basic Auth 认证
set USERNAME=
set PASSWORD=

REM 服务器端口
set PORT=5000

REM 数据文件路径
set DATA_FILE=vaultsafe_sync.json
REM ==================================================

echo 当前配置:
echo   端口: %PORT%
echo   数据文件: %DATA_FILE%
echo.

if not "%TOKEN%"=="" (
    echo   Bearer Token: 已设置
) else (
    echo   Bearer Token: 未设置
)

if not "%USERNAME%"=="" (
    echo   Basic Auth: %USERNAME%:***
) else (
    echo   Basic Auth: 未设置
)

if "%TOKEN%"=="" if "%USERNAME%"=="" (
    echo.
    echo   ⚠️  警告: 未启用认证！
    echo.
)

echo.
echo 启动服务器...
echo.

REM 设置环境变量并启动
if not "%TOKEN%"=="" set VAULTSAFE_API_TOKEN=%TOKEN%
if not "%USERNAME%"=="" set VAULTSAFE_USERNAME=%USERNAME%
if not "%PASSWORD%"=="" set VAULTSAFE_PASSWORD=%PASSWORD%
set VAULTSAFE_PORT=%PORT%
set VAULTSAFE_DATA_FILE=%DATA_FILE%

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到 Python，请先安装 Python 3.6+
    pause
    exit /b 1
)

REM 检查Flask是否安装
python -c "import flask" >nul 2>&1
if errorlevel 1 (
    echo 正在安装 Flask 依赖...
    pip install flask flask-cors
    if errorlevel 1 (
        echo 错误: 安装依赖失败
        pause
        exit /b 1
    )
)

REM 启动服务器
python sync_server.py

pause
