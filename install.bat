@echo off
REM VaultSafe Install Script (Batch)
REM Usage:
REM   Local:  install.bat
REM   Remote: curl -fsSL -o "%TEMP%\install.bat" https://gitee.com/baichen9187/vaultsafe-passwrod/raw/master/install.bat && "%TEMP%\install.bat"

set VERSION=1.0.4
set APP_NAME=VaultSafe
set BASE_URL=https://gitee.com/baichen9187/vaultsafe-passwrod/releases/download
set ZIP_FILE=%APP_NAME%-%VERSION%-windows-x64.zip
set DOWNLOAD_URL=%BASE_URL%/%VERSION%/%ZIP_FILE%
set INSTALL_DIR=%LOCALAPPDATA%\%APP_NAME%

echo ========================================
echo   %APP_NAME% v%VERSION% Installer
echo ========================================
echo.

REM Download
echo [1/3] Downloading %ZIP_FILE% ...
echo   URL: %DOWNLOAD_URL%
set TEMP_ZIP=%TEMP%\%ZIP_FILE%
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_ZIP%' -UseBasicParsing"
if %ERRORLEVEL% neq 0 (
    echo Error: Download failed.
    pause
    exit /b 1
)
echo   Download complete.
echo.

REM Extract
echo [2/3] Extracting to %INSTALL_DIR% ...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%INSTALL_DIR%' -Force"
del /f /q "%TEMP_ZIP%"
echo   Extracted.
echo.

REM Create shortcuts
echo [3/3] Creating shortcuts ...
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $exe = Get-ChildItem '%INSTALL_DIR%' -Filter '*.exe' -Recurse | Select -First 1; if ($exe) { $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\%APP_NAME%.lnk'); $s.TargetPath = $exe.FullName; $s.WorkingDirectory = $exe.DirectoryName; $s.Save(); $s = $ws.CreateShortcut([Environment]::GetFolderPath('StartMenu') + '\%APP_NAME%.lnk'); $s.TargetPath = $exe.FullName; $s.WorkingDirectory = $exe.DirectoryName; $s.Save(); Write-Host '  Desktop shortcut created.'; Write-Host '  Start Menu shortcut created.' } else { Write-Host '  Warning: No .exe found.' }"
echo.

echo ========================================
echo   %APP_NAME% v%VERSION% installed!
echo   Location: %INSTALL_DIR%
echo   Double-click desktop shortcut to start.
echo ========================================
pause
