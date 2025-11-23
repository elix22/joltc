#!/bin/bash
# Build script for joltc library for Linux
# Usage: ./build-joltc-linux.sh [build_type]
# Example: ./build-joltc-linux.sh Release
# Example: ./build-joltc-linux.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
BUILD_TYPE="${1:-Release}"
BUILD_DIR="$JOLTC_DIR/build-linux"

echo "=========================================="
echo "Building joltc for Linux"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
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
cmake --build . --config "$BUILD_TYPE" --target joltc -- -j$(nproc)

# Create destination directory
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
DEST_DIR="$JOLTC_DIR/libs/linux/X64/$BUILD_TYPE_LOWER"
mkdir -p "$DEST_DIR"

# Copy library to destination
echo "Copying library to $DEST_DIR..."
LIB_PATH="$BUILD_DIR/lib/libjoltc.so"

if [ -f "$LIB_PATH" ]; then
    cp -P "$BUILD_DIR/lib/"libjoltc.so* "$DEST_DIR/" 2>/dev/null || cp "$LIB_PATH" "$DEST_DIR/"
    # Also copy libJolt.so dependency
    if [ -f "$BUILD_DIR/lib/libJolt.so" ]; then
        cp -P "$BUILD_DIR/lib/"libJolt.so* "$DEST_DIR/" 2>/dev/null || cp "$BUILD_DIR/lib/libJolt.so" "$DEST_DIR/"
        echo "✓ Copied libJolt.so"
    fi
elif [ -f "$BUILD_DIR/bin/libjoltc.so" ]; then
    cp -P "$BUILD_DIR/bin/"libjoltc.so* "$DEST_DIR/" 2>/dev/null || cp "$BUILD_DIR/bin/libjoltc.so" "$DEST_DIR/"
    # Also copy libJolt.so dependency
    if [ -f "$BUILD_DIR/bin/libJolt.so" ]; then
        cp -P "$BUILD_DIR/bin/"libJolt.so* "$DEST_DIR/" 2>/dev/null || cp "$BUILD_DIR/bin/libJolt.so" "$DEST_DIR/"
        echo "✓ Copied libJolt.so"
    fi
elif [ -f "$BUILD_DIR/libjoltc.so" ]; then
    cp -P "$BUILD_DIR/"libjoltc.so* "$DEST_DIR/" 2>/dev/null || cp "$BUILD_DIR/libjoltc.so" "$DEST_DIR/"
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
    echo "✓ Successfully built libjoltc.so"
    file "$DEST_DIR/libjoltc.so"
    ls -lh "$DEST_DIR"
else
    echo "✗ Failed to build libjoltc.so"
    exit 1
fi
