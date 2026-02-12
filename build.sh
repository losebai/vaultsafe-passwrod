#!/bin/bash

# VaultSafe Build Script

echo "================================"
echo "  VaultSafe Build Script"
echo "================================"
echo ""

# Check Flutter environment
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found! Please install Flutter first."
    exit 1
fi

# Main menu loop
while true; do
    echo ""
    echo "Please select build type:"
    echo "[1] APK - arm64-v8a (Recommended, ~20MB)"
    echo "[2] APK - armeabi-v7a (32-bit devices)"
    echo "[3] App Bundle (All architectures, optimized)"
    echo "[4] Clean build cache"
    echo "[5] Exit"
    echo ""

    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            clear
            echo ""
            echo "Building arm64-v8a APK..."
            if flutter build apk --release --target-platform android-arm64; then
                # Read version from pubspec.yaml
                VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
                VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)

                # Rename APK with version and architecture
                mv "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/vaultsafe-${VERSION_CLEAN}-arm64-v8a.apk" 2>/dev/null

                echo ""
                echo "[OK] Build completed!"
                echo ""
                echo "Output: build/app/outputs/flutter-apk/vaultsafe-${VERSION_CLEAN}-arm64-v8a.apk"
            else
                echo ""
                echo "[ERROR] Build failed, please check error messages above"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;

        2)
            clear
            echo ""
            echo "Building armeabi-v7a APK (32-bit devices)..."
            if flutter build apk --release --target-platform android-armeabi-v7a; then
                # Read version from pubspec.yaml
                VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
                VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)

                # Rename APK with version and architecture
                mv "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/vaultsafe-${VERSION_CLEAN}-armeabi-v7a.apk" 2>/dev/null

                echo ""
                echo "[OK] Build completed!"
                echo ""
                echo "Output: build/app/outputs/flutter-apk/vaultsafe-${VERSION_CLEAN}-armeabi-v7a.apk"
            else
                echo ""
                echo "[ERROR] Build failed, please check error messages above"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;

        3)
            clear
            echo ""
            echo "Building App Bundle (all architectures, optimized)..."
            if flutter build appbundle --release; then
                # Read version from pubspec.yaml
                VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
                VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)

                # Rename AAB with version
                mv "build/app/outputs/bundle/release/app-release.aab" "build/app/outputs/bundle/release/vaultsafe-${VERSION_CLEAN}-universal.aab" 2>/dev/null

                echo ""
                echo "[OK] Build completed!"
                echo ""
                echo "Output: build/app/outputs/bundle/release/vaultsafe-${VERSION_CLEAN}-universal.aab"
            else
                echo ""
                echo "[ERROR] Build failed, please check error messages above"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;

        4)
            clear
            echo ""
            echo "Cleaning build cache..."
            if flutter clean; then
                echo ""
                echo "[OK] Cache cleared!"
            else
                echo ""
                echo "[ERROR] Clean operation failed"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;

        5)
            clear
            echo ""
            echo "Goodbye!"
            exit 0
            ;;

        *)
            echo ""
            echo "Invalid choice, please try again"
            sleep 1
            clear
            ;;
    esac
done
