#!/bin/bash
# Build script for building joltc for all platforms
# Usage: ./build-all.sh [build_type]
# Example: ./build-all.sh Release
# Example: ./build-all.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${1:-Release}"

echo "=========================================="
echo "Building joltc for all platforms"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Detect operating system
OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    echo ""
    echo "Building for macOS (both architectures)..."
    "$SCRIPT_DIR/build-joltc-macos.sh" "arm64" "$BUILD_TYPE"
    "$SCRIPT_DIR/build-joltc-macos.sh" "x86_64" "$BUILD_TYPE"
    
    echo ""
    echo "Building for iOS..."
    "$SCRIPT_DIR/build-joltc-ios.sh" "$BUILD_TYPE"
    
elif [ "$OS" = "Linux" ]; then
    echo ""
    echo "Building for Linux..."
    "$SCRIPT_DIR/build-joltc-linux.sh" "$BUILD_TYPE"
    
else
    echo "Error: Unsupported operating system: $OS"
    echo "Please use macOS or Linux to run this script"
    exit 1
fi

# Build for Android (if NDK is available)
if [ -n "$ANDROID_NDK" ] || [ -n "$ANDROID_NDK_HOME" ]; then
    echo ""
    echo "Building for Android (all ABIs)..."
    "$SCRIPT_DIR/build-joltc-android.sh" "arm64-v8a" "$BUILD_TYPE"
    "$SCRIPT_DIR/build-joltc-android.sh" "armeabi-v7a" "$BUILD_TYPE"
    "$SCRIPT_DIR/build-joltc-android.sh" "x86_64" "$BUILD_TYPE"
    "$SCRIPT_DIR/build-joltc-android.sh" "x86" "$BUILD_TYPE"
else
    echo ""
    echo "Skipping Android build (ANDROID_NDK not set)"
fi

# Build for Web/Emscripten
echo ""
echo "Building for Web/Emscripten..."
"$SCRIPT_DIR/build-joltc-web.sh" "$BUILD_TYPE"

echo ""
echo "=========================================="
echo "All builds complete!"
echo "=========================================="
