#!/bin/bash
# Build script for joltc library for Android
# Usage: ./build-joltc-android.sh [abi] [build_type]
# Example: ./build-joltc-android.sh arm64-v8a Release
# Example: ./build-joltc-android.sh armeabi-v7a Debug
# Supported ABIs: arm64-v8a, armeabi-v7a, x86, x86_64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
ANDROID_ABI="${1:-arm64-v8a}"
BUILD_TYPE="${2:-Release}"
BUILD_DIR="$JOLTC_DIR/build-android-$ANDROID_ABI"

echo "=========================================="
echo "Building joltc for Android"
echo "ABI: $ANDROID_ABI"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Check for Android NDK
if [ -z "$ANDROID_NDK" ]; then
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "Error: ANDROID_NDK or ANDROID_NDK_HOME environment variable not set"
        echo "Please set one of these to your Android NDK path"
        exit 1
    fi
    ANDROID_NDK="$ANDROID_NDK_HOME"
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo "Error: Android NDK not found at: $ANDROID_NDK"
    exit 1
fi

echo "Using Android NDK: $ANDROID_NDK"

# Determine API level
ANDROID_NATIVE_API_LEVEL="${ANDROID_NATIVE_API_LEVEL:-21}"
echo "API Level: $ANDROID_NATIVE_API_LEVEL"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$ANDROID_ABI" \
    -DANDROID_NATIVE_API_LEVEL="$ANDROID_NATIVE_API_LEVEL" \
    -DANDROID_STL=c++_shared \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBUILD_SHARED_LIBS=ON \
    -DTARGET_UNIT_TESTS=OFF \
    -DTARGET_HELLO_WORLD=OFF \
    -DTARGET_PERFORMANCE_TEST=OFF \
    -DTARGET_SAMPLES=OFF \
    -DTARGET_VIEWER=OFF \
    -DENABLE_ALL_WARNINGS=OFF \
    -DTARGET_01_HELLOWORLD=OFF \
    -DENABLE_SAMPLES=OFF \
    -DCMAKE_C_FLAGS="-fno-omit-frame-pointer -Os" \
    -DCMAKE_CXX_FLAGS="-fno-omit-frame-pointer -fno-strict-aliasing -Os -ffunction-sections -fdata-sections" \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--gc-sections"

# Build only joltc target (not samples)
cmake --build . --config "$BUILD_TYPE" --target joltc -- -j$(nproc)

# Create destination directory
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
DEST_DIR="$JOLTC_DIR/libs/android/$ANDROID_ABI/$BUILD_TYPE_LOWER"
mkdir -p "$DEST_DIR"

# Copy library to destination
echo "Copying library to $DEST_DIR..."
LIB_PATH="$BUILD_DIR/lib/libjoltc.so"

if [ -f "$LIB_PATH" ]; then
    cp "$LIB_PATH" "$DEST_DIR/"
    # Also copy libJolt.so dependency
    if [ -f "$BUILD_DIR/lib/libJolt.so" ]; then
        cp "$BUILD_DIR/lib/libJolt.so" "$DEST_DIR/"
        echo "✓ Copied libJolt.so"
    fi
elif [ -f "$BUILD_DIR/bin/libjoltc.so" ]; then
    cp "$BUILD_DIR/bin/libjoltc.so" "$DEST_DIR/"
    # Also copy libJolt.so dependency
    if [ -f "$BUILD_DIR/bin/libJolt.so" ]; then
        cp "$BUILD_DIR/bin/libJolt.so" "$DEST_DIR/"
        echo "✓ Copied libJolt.so"
    fi
elif [ -f "$BUILD_DIR/libjoltc.so" ]; then
    cp "$BUILD_DIR/libjoltc.so" "$DEST_DIR/"
else
    echo "Error: libjoltc.so not found"
    echo "Searched paths:"
    echo "  - $BUILD_DIR/lib/libjoltc.so"
    echo "  - $BUILD_DIR/bin/libjoltc.so"
    echo "  - $BUILD_DIR/libjoltc.so"
    exit 1
fi

echo "=========================================="
echo "Build complete!"
echo "Output: $DEST_DIR/libjoltc.so"
echo "=========================================="

# Verify the library was created
if [ -f "$DEST_DIR/libjoltc.so" ]; then
    echo "✓ Successfully built libjoltc.so for $ANDROID_ABI"
    ls -lh "$DEST_DIR/libjoltc.so"
else
    echo "✗ Failed to build libjoltc.so"
    exit 1
fi
