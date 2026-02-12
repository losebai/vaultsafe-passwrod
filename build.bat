@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

:main_menu
cls
echo ========================================
echo   VaultSafe Build Script
echo ========================================
echo.

echo Please select build type:
echo [1] APK - arm64-v8a (Recommended, ~20MB)
echo [2] APK - armeabi-v7a (32-bit devices)
echo [3] App Bundle (All architectures, optimized)
echo [4] Clean build cache
echo [5] Exit
echo.

set choice=
set /p choice=Enter your choice (1-5):

if /i "%choice%"=="1" goto :apk_arm64
if /i "%choice%"=="2" goto :apk_armeabi
if /i "%choice%"=="3" goto :appbundle
if /i "%choice%"=="4" goto :clean
if /i "%choice%"=="5" goto :exit

REM Invalid choice, show menu again
goto :main_menu

:apk_arm64
cls
echo.
echo Building arm64-v8a APK...
call flutter build apk --release --target-platform android-arm64
if errorlevel 1 goto :error

REM Read version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('type pubspec.yaml ^| findstr "^version:"') do set VERSION_RAW=%%a
set VERSION=%VERSION_RAW: =%
set VERSION=%VERSION:"=%
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set VERSION_CLEAN=%%a

REM Rename APK with version and architecture
move "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\vaultsafe-%VERSION_CLEAN%-arm64-v8a.apk" >nul 2>&1

echo.
echo [OK] Build completed!
echo.
echo Output: build\app\outputs\flutter-apk\vaultsafe-%VERSION_CLEAN%-arm64-v8a.apk
echo.
pause
goto :main_menu

:apk_armeabi
cls
echo.
echo Building armeabi-  APK (32-bit devices)...
call flutter build apk --release --target-platform android-armeabi-v7a
if errorlevel 1 goto :error

REM Read version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('type pubspec.yaml ^| findstr "^version:"') do set VERSION_RAW=%%a
set VERSION=%VERSION_RAW: =%
set VERSION=%VERSION:"=%
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set VERSION_CLEAN=%%a

REM Rename APK with version and architecture
move "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\vaultsafe-%VERSION_CLEAN%-armeabi-v7a.apk" >nul 2>&1

echo.
echo [OK] Build completed!
echo.
echo Output: build\app\outputs\flutter-apk\vaultsafe-%VERSION_CLEAN%-armeabi-v7a.apk
echo.
pause
goto :main_menu

:appbundle
cls
echo.
echo Building App Bundle (all architectures, optimized)...
call flutter build appbundle --release
if errorlevel 1 goto :error

REM Read version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('type pubspec.yaml ^| findstr "^version:"') do set VERSION_RAW=%%a
set VERSION=%VERSION_RAW: =%
set VERSION=%VERSION:"=%
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set VERSION_CLEAN=%%a

REM Rename AAB with version
move "build\app\outputs\bundle\release\app-release.aab" "build\app\outputs\bundle\release\vaultsafe-%VERSION_CLEAN%-universal.aab" >nul 2>&1

echo.
echo [OK] Build completed!
echo.
echo Output: build\app\outputs\bundle\release\vaultsafe-%VERSION_CLEAN%-universal.aab
echo.
pause
goto :main_menu

:clean
cls
echo.
echo Cleaning build cache...
call flutter clean
if errorlevel 1 goto :error
echo.
echo [OK] Cache cleared!
echo.
pause
goto :main_menu

:error
echo.
echo [ERROR] Build failed, please check error messages above
echo.
pause
goto :main_menu

:exit
cls
echo.
echo Goodbye!
timeout /t 1 >nul
exit /b 0
