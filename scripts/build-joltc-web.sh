#!/bin/bash
# Build script for joltc library for Web/Emscripten
# Usage: ./build-joltc-web.sh [build_type]
# Example: ./build-joltc-web.sh Release
# Example: ./build-joltc-web.sh Debug

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOKOL_CHARP_ROOT="$(cd "$JOLTC_DIR/../.." && pwd)"

# Parse arguments
BUILD_TYPE="${1:-Release}"

# Set Emscripten version
EMSCRIPTEN_VERSION="3.1.34"

echo "=========================================="
echo "Building joltc for Web/Emscripten"
echo "Build Type: $BUILD_TYPE"
echo "Emscripten Version: $EMSCRIPTEN_VERSION"
echo "=========================================="

# Path to local emsdk
EMSDK_PATH="$SOKOL_CHARP_ROOT/tools/emsdk/emsdk"

# Check if local emsdk exists
if [ -f "$EMSDK_PATH" ]; then
    echo "Using local emsdk from Sokol.NET..."
    
    # Make emsdk executable if it isn't already
    chmod +x "$EMSDK_PATH"
    
    # Activate Emscripten SDK with the specified version
    echo "Installing Emscripten SDK version $EMSCRIPTEN_VERSION..."
    "$EMSDK_PATH" install "$EMSCRIPTEN_VERSION"
    
    echo "Activating Emscripten SDK version $EMSCRIPTEN_VERSION..."
    "$EMSDK_PATH" activate "$EMSCRIPTEN_VERSION"
    
    # Set up environment variables for Emscripten
    echo "Setting up Emscripten environment..."
    source "$SOKOL_CHARP_ROOT/tools/emsdk/emsdk_env.sh"
else
    echo "Local emsdk not found, using system emscripten (assuming CI environment)..."
    
    # Check if emcc is available
    if ! command -v emcc &> /dev/null; then
        echo "Error: emcc not found in PATH"
        echo "Please install Emscripten or run from Sokol.NET with emsdk submodule initialized"
        exit 1
    fi
    
    # Verify emscripten version
    EMCC_VERSION=$(emcc --version | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    echo "Found Emscripten version: $EMCC_VERSION"
    
    if [ "$EMCC_VERSION" != "$EMSCRIPTEN_VERSION" ]; then
        echo "Warning: Emscripten version mismatch (expected $EMSCRIPTEN_VERSION, found $EMCC_VERSION)"
        echo "Continuing anyway..."
    fi
fi

echo "Using Emscripten: $(emcc --version | head -n 1)"

# Determine build directory based on build type
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
BUILD_DIR="$JOLTC_DIR/build-emscripten-$BUILD_TYPE_LOWER"

# Clean up existing build directory for a fresh build
echo "Cleaning build directory: $BUILD_DIR"
rm -rf "$BUILD_DIR"

# Create build directory
echo "Creating build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake using Emscripten toolchain
echo "Configuring CMake..."
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBUILD_SHARED_LIBS=OFF \
    -DTARGET_UNIT_TESTS=OFF \
    -DTARGET_HELLO_WORLD=OFF \
    -DTARGET_PERFORMANCE_TEST=OFF \
    -DTARGET_SAMPLES=OFF \
    -DTARGET_VIEWER=OFF \
    -DENABLE_ALL_WARNINGS=OFF \
    -DTARGET_01_HELLOWORLD=OFF \
    -DENABLE_SAMPLES=OFF

# Build only joltc target (not samples)
echo "Building joltc target only..."
cmake --build . --config "$BUILD_TYPE" --target joltc

# Create destination directory
DEST_DIR="$JOLTC_DIR/libs/emscripten/x86/$BUILD_TYPE_LOWER"
mkdir -p "$DEST_DIR"

# Copy library to destination (rename to joltc.a)
echo "Copying library to $DEST_DIR..."
if [ -f "$BUILD_DIR/lib/libjoltc.a" ]; then
    cp "$BUILD_DIR/lib/libjoltc.a" "$DEST_DIR/joltc.a"
elif [ -f "$BUILD_DIR/libjoltc.a" ]; then
    cp "$BUILD_DIR/libjoltc.a" "$DEST_DIR/joltc.a"
else
    echo "Error: libjoltc.a not found"
    echo "Searched paths:"
    echo "  - $BUILD_DIR/lib/libjoltc.a"
    echo "  - $BUILD_DIR/libjoltc.a"
    exit 1
fi

# Also copy libJolt.a dependency
echo "Copying libJolt.a dependency..."
if [ -f "$BUILD_DIR/lib/libJolt.a" ]; then
    cp "$BUILD_DIR/lib/libJolt.a" "$DEST_DIR/libJolt.a"
    echo "✓ Copied libJolt.a"
elif [ -f "$BUILD_DIR/libJolt.a" ]; then
    cp "$BUILD_DIR/libJolt.a" "$DEST_DIR/libJolt.a"
    echo "✓ Copied libJolt.a"
else
    echo "Warning: libJolt.a not found at expected locations"
fi

echo "=========================================="
echo "Build complete!"
echo "Output: $DEST_DIR/joltc.a"
echo "=========================================="

# Verify the library was created
if [ -f "$DEST_DIR/joltc.a" ]; then
    echo "✓ Successfully built joltc.a"
    ls -lh "$DEST_DIR/joltc.a"
else
    echo "✗ Failed to build joltc.a"
    exit 1
fi
