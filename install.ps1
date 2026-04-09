# VaultSafe Install Script (PowerShell)
# Usage:
#   Local: .\install.ps1
#   Remote: irm https://gitee.com/baichen9187/vaultsafe-passwrod/raw/master/install.ps1 | iex

$Version = "1.0.4"
$AppName = "VaultSafe"
$BaseURL = "https://gitee.com/baichen9187/vaultsafe-passwrod/releases/download"
$ZipFile = "$AppName-$Version-windows-x64.zip"
$DownloadURL = "$BaseURL/$Version/$ZipFile"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  $AppName v$Version Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Install directory
$InstallDir = "$env:LOCALAPPDATA\$AppName"

Write-Host "[1/4] Downloading $ZipFile ..." -ForegroundColor Yellow
Write-Host "  URL: $DownloadURL" -ForegroundColor Gray

$TempZip = "$env:TEMP\$ZipFile"
try {
    Invoke-WebRequest -Uri $DownloadURL -OutFile $TempZip -UseBasicParsing
} catch {
    Write-Host "Error: Download failed. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "  Download complete." -ForegroundColor Green

# Extract
Write-Host ""
Write-Host "[2/4] Extracting to $InstallDir ..." -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
}
Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
Remove-Item $TempZip -Force
Write-Host "  Extracted." -ForegroundColor Green

# Find executable
$ExePath = Get-ChildItem -Path $InstallDir -Filter "$AppName.exe" -Recurse | Select-Object -First 1
if ($null -eq $ExePath) {
    # Try finding any .exe in the directory
    $ExePath = Get-ChildItem -Path $InstallDir -Filter "*.exe" -Recurse | Select-Object -First 1
}

# Create shortcut
Write-Host ""
Write-Host "[3/4] Creating shortcut ..." -ForegroundColor Yellow
$Desktop = [Environment]::GetFolderPath("Desktop")
$StartMenu = [Environment]::GetFolderPath("StartMenu")
$WshShell = New-Object -ComObject WScript.Shell

if ($null -ne $ExePath) {
    $Target = $ExePath.FullName
    # Desktop shortcut
    $Shortcut = $WshShell.CreateShortcut("$Desktop\$AppName.lnk")
    $Shortcut.TargetPath = $Target
    $Shortcut.WorkingDirectory = $ExePath.DirectoryName
    $Shortcut.Save()
    # Start Menu shortcut
    $Shortcut = $WshShell.CreateShortcut("$StartMenu\$AppName.lnk")
    $Shortcut.TargetPath = $Target
    $Shortcut.WorkingDirectory = $ExePath.DirectoryName
    $Shortcut.Save()
    Write-Host "  Shortcuts created." -ForegroundColor Green
} else {
    Write-Host "  Warning: No .exe found, skipping shortcut creation." -ForegroundColor Yellow
}

# Add to PATH
Write-Host ""
Write-Host "[4/4] Adding to PATH ..." -ForegroundColor Yellow
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -ne $ExePath -and $CurrentPath -notlike "*$($ExePath.DirectoryName)*") {
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$($ExePath.DirectoryName)", "User")
    Write-Host "  Added to user PATH." -ForegroundColor Green
} else {
    Write-Host "  Already in PATH." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  $AppName v$Version installed!" -ForegroundColor Green
Write-Host "  Location: $InstallDir" -ForegroundColor Cyan
if ($null -ne $ExePath) {
    Write-Host "  Run: $($ExePath.Name)" -ForegroundColor Cyan
}
Write-Host "========================================" -ForegroundColor Cyan
