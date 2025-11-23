#!/bin/bash
# Build script for joltc library for all Android architectures
# Usage: ./build-joltc-android-all.sh [build_type]
# Example: ./build-joltc-android-all.sh Release
# Example: ./build-joltc-android-all.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${1:-Release}"

echo "=========================================="
echo "Building joltc for all Android architectures"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Android ABIs to build (matching sokol library architectures)
ANDROID_ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")

for ABI in "${ANDROID_ABIS[@]}"; do
    echo ""
    echo "Building for Android $ABI..."
    "$SCRIPT_DIR/build-joltc-android.sh" "$ABI" "$BUILD_TYPE"
done

echo ""
echo "=========================================="
echo "All Android builds completed successfully!"
echo "=========================================="

# Show built libraries
echo ""
echo "Built libraries:"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')

for ABI in "${ANDROID_ABIS[@]}"; do
    LIB_PATH="$JOLTC_DIR/libs/android/$ABI/$BUILD_TYPE_LOWER/libjoltc.so"
    if [ -f "$LIB_PATH" ]; then
        echo "  ✓ $ABI: $LIB_PATH"
        ls -lh "$LIB_PATH"
    else
        echo "  ✗ $ABI: Not found"
    fi
done
