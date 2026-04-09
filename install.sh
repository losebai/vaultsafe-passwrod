#!/bin/bash
# VaultSafe Install Script (Bash)
# Usage:
#   Local:  chmod +x install.sh && ./install.sh
#   Remote: curl -fsSL https://gitee.com/baichen9187/vaultsafe-passwrod/raw/master/install.sh | bash

VERSION="1.0.4"
APP_NAME="VaultSafe"
BASE_URL="https://gitee.com/baichen9187/vaultsafe-passwrod/releases/download"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"

# Detect platform
detect_platform() {
    local arch="$(uname -m)"
    case "$arch" in
        x86_64) echo "x64" ;;
        arm64|aarch64) echo "arm64" ;;
        *) echo "x64" ;;
    esac
}

PLATFORM="$(detect_platform)"

if [[ "$OSTYPE" == "darwin"* ]]; then
    ZIP_FILE="$APP_NAME-$VERSION-macos-$PLATFORM.zip"
elif [[ "$OSTYPE" == "linux"* ]]; then
    ZIP_FILE="$APP_NAME-$VERSION-linux-$PLATFORM.zip"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

DOWNLOAD_URL="$BASE_URL/$VERSION/$ZIP_FILE"

echo "========================================"
echo "  $APP_NAME v$VERSION Installer"
echo "========================================"
echo ""

# Download
echo "[1/3] Downloading $ZIP_FILE ..."
echo "  URL: $DOWNLOAD_URL"
TEMP_ZIP="/tmp/$ZIP_FILE"
if command -v curl &> /dev/null; then
    curl -fSL -o "$TEMP_ZIP" "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -O "$TEMP_ZIP" "$DOWNLOAD_URL"
else
    echo "Error: curl or wget required."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "Error: Download failed."
    exit 1
fi
echo "  Download complete."

# Extract
echo ""
echo "[2/3] Extracting to $INSTALL_DIR ..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q -o "$TEMP_ZIP" -d "$INSTALL_DIR"
rm -f "$TEMP_ZIP"
echo "  Extracted."

# Find executable
BINARY=$(find "$INSTALL_DIR" -name "$APP_NAME" -o -name "$APP_NAME.app" | head -1)
if [ -z "$BINARY" ]; then
    BINARY=$(find "$INSTALL_DIR" -type f -perm -u+x | head -1)
fi

# Create shortcut
echo ""
echo "[3/3] Creating shortcut ..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: copy to /Applications
    APP_BUNDLE=$(find "$INSTALL_DIR" -name "*.app" | head -1)
    if [ -n "$APP_BUNDLE" ]; then
        cp -R "$APP_BUNDLE" "/Applications/$APP_NAME.app" 2>/dev/null
        echo "  Copied to /Applications/$APP_NAME.app"
    fi
fi

if [ -n "$BINARY" ]; then
    chmod +x "$BINARY"
    echo "  Binary ready: $BINARY"
else
    echo "  Warning: No binary found."
fi

echo ""
echo "========================================"
echo "  $APP_NAME v$VERSION installed!"
echo "  Location: $INSTALL_DIR"
if [ -n "$BINARY" ]; then
    echo "  Run: $APP_NAME"
fi
echo "========================================"
