#!/bin/bash
# Build script for joltc library on macOS
# Usage: ./build-joltc-macos.sh [architecture] [build_type]
# Example: ./build-joltc-macos.sh arm64 Release
# Example: ./build-joltc-macos.sh x86_64 Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$JOLTC_DIR/build-xcode-macos"

# Parse arguments
ARCH="${1:-arm64}"
BUILD_TYPE="${2:-Release}"

# Normalize architecture for directory naming (x86_64 -> X64)
ARCH_DIR="$ARCH"
if [ "$ARCH" = "x86_64" ]; then
    ARCH_DIR="X64"
fi

echo "=========================================="
echo "Building joltc for macOS"
echo "Architecture: $ARCH"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
cmake .. \
    -G Xcode \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DBUILD_SHARED_LIBS=ON \
    -DTARGET_UNIT_TESTS=OFF \
    -DTARGET_HELLO_WORLD=OFF \
    -DTARGET_PERFORMANCE_TEST=OFF \
    -DTARGET_SAMPLES=OFF \
    -DTARGET_VIEWER=OFF \
    -DENABLE_ALL_WARNINGS=OFF \
    -DTARGET_01_HELLOWORLD=OFF \
    -DENABLE_SAMPLES=OFF

# Build only joltc target (not samples)
cmake --build . --config "$BUILD_TYPE" --target joltc

# Create destination directory using normalized architecture
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
DEST_DIR="$JOLTC_DIR/libs/macos/$ARCH_DIR/$BUILD_TYPE_LOWER"
mkdir -p "$DEST_DIR"

# Copy library to destination (actual file, not symlink)
echo "Copying library to $DEST_DIR..."

# Find the joltc library - try multiple possible locations
LIB_PATH="$BUILD_DIR/lib/$BUILD_TYPE/libjoltc.dylib"

if [ ! -f "$LIB_PATH" ]; then
    # Try bin directory
    LIB_PATH="$BUILD_DIR/bin/$BUILD_TYPE/libjoltc.dylib"
fi

if [ ! -f "$LIB_PATH" ]; then
    # Try root build type directory
    LIB_PATH="$BUILD_DIR/$BUILD_TYPE/libjoltc.dylib"
fi

if [ -f "$LIB_PATH" ]; then
    # Copy to destination first
    cp "$LIB_PATH" "$DEST_DIR/libjoltc.dylib"
    
    # Strip and re-sign in destination to ensure unique signature
    echo "Stripping and re-signing libjoltc.dylib..."
    codesign --remove-signature "$DEST_DIR/libjoltc.dylib" 2>/dev/null || true
    # Add timestamp to identifier to make each build unique
    TIMESTAMP=$(date +%s)
    codesign --force --sign - --identifier "libjoltc.${TIMESTAMP}" "$DEST_DIR/libjoltc.dylib"
    echo "Copied libjoltc.dylib"
    
    # Also copy libJolt.dylib dependency
    JOLT_LIB_PATH="$BUILD_DIR/lib/$BUILD_TYPE/libJolt.dylib"
    if [ -f "$JOLT_LIB_PATH" ]; then
        # Copy to destination first
        cp "$JOLT_LIB_PATH" "$DEST_DIR/libJolt.dylib"
        
        # Strip and re-sign in destination to ensure unique signature
        echo "Stripping and re-signing libJolt.dylib..."
        codesign --remove-signature "$DEST_DIR/libJolt.dylib" 2>/dev/null || true
        # Add timestamp to identifier to make each build unique
        codesign --force --sign - --identifier "libJolt.${TIMESTAMP}" "$DEST_DIR/libJolt.dylib"
        echo "Copied libJolt.dylib"
    else
        echo "Warning: libJolt.dylib not found at $JOLT_LIB_PATH"
    fi
else
    echo "Error: libjoltc.dylib not found"
    echo "Searched paths:"
    echo "  - $BUILD_DIR/lib/$BUILD_TYPE/libjoltc.dylib"
    echo "  - $BUILD_DIR/bin/$BUILD_TYPE/libjoltc.dylib"
    echo "  - $BUILD_DIR/$BUILD_TYPE/libjoltc.dylib"
    exit 1
fi

echo "=========================================="
echo "Build complete!"
echo "Output: $DEST_DIR/libjoltc.dylib"
echo "=========================================="

# Verify the library was created
if [ -f "$DEST_DIR/libjoltc.dylib" ]; then
    echo "✓ Successfully built libjoltc.dylib"
    ls -lh "$DEST_DIR/libjoltc.dylib"
else
    echo "✗ Failed to build libjoltc.dylib"
    exit 1
fi
