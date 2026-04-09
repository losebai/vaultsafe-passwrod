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

Write-Host "[1/3] Downloading $ZipFile ..." -ForegroundColor Yellow
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
Write-Host "[2/3] Extracting to $InstallDir ..." -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
}
Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
Remove-Item $TempZip -Force
Write-Host "  Extracted." -ForegroundColor Green

# Find executable
$ExePath = Get-ChildItem -Path $InstallDir -Filter "$AppName.exe" -Recurse | Select-Object -First 1
if ($null -eq $ExePath) {
    $ExePath = Get-ChildItem -Path $InstallDir -Filter "*.exe" -Recurse | Select-Object -First 1
}

# Create shortcut
Write-Host ""
Write-Host "[3/3] Creating shortcuts ..." -ForegroundColor Yellow
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
    Write-Host "  Desktop:   $Desktop\$AppName.lnk" -ForegroundColor Green
    Write-Host "  Start Menu: $StartMenu\$AppName.lnk" -ForegroundColor Green
} else {
    Write-Host "  Warning: No .exe found, skipping shortcut creation." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  $AppName v$Version installed!" -ForegroundColor Green
Write-Host "  Location: $InstallDir" -ForegroundColor Cyan
if ($null -ne $ExePath) {
    Write-Host "  Double-click desktop shortcut to start." -ForegroundColor Cyan
}
Write-Host "========================================" -ForegroundColor Cyan
