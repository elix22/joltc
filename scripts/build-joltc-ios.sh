#!/bin/bash
# Build script for joltc library for iOS
# Builds a dynamic framework for iOS device only
# Usage: ./build-joltc-ios.sh [build_type]
# Example: ./build-joltc-ios.sh Release
# Example: ./build-joltc-ios.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOLTC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
BUILD_TYPE="${1:-Release}"

echo "=========================================="
echo "Building joltc for iOS (device only)"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Check if we're on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: iOS builds require macOS"
    exit 1
fi

# Build for device (arm64)
echo ""
echo "Building for iOS device (arm64)..."
BUILD_DIR_DEVICE="$JOLTC_DIR/build-ios-device"
rm -rf "$BUILD_DIR_DEVICE"
mkdir -p "$BUILD_DIR_DEVICE"
cd "$BUILD_DIR_DEVICE"

# Configure with CMake for device
# Build both Jolt and joltc as dynamic libraries for framework creation
# Force JPH_BUILD_SHARED=ON to override the iOS default in CMakeLists.txt
cmake .. \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_ARCHITECTURES="arm64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DJPH_BUILD_SHARED=ON \
    -DTARGET_UNIT_TESTS=OFF \
    -DTARGET_HELLO_WORLD=OFF \
    -DTARGET_PERFORMANCE_TEST=OFF \
    -DTARGET_SAMPLES=OFF \
    -DTARGET_VIEWER=OFF \
    -DENABLE_ALL_WARNINGS=OFF \
    -DTARGET_01_HELLOWORLD=OFF \
    -DENABLE_SAMPLES=OFF \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
    -DPRODUCT_BUNDLE_IDENTIFIER="com.joltc.library"

# Build joltc target specifically (builds both Jolt and joltc as dynamic libraries)
cmake --build . --config Release --target joltc -- -sdk iphoneos CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Find the built libraries (both should be dynamic for frameworks)
echo ""
echo "Locating built libraries..."
JOLTC_DYLIB=$(find "$BUILD_DIR_DEVICE" -name "libjoltc*.dylib" -type f | head -n 1)
JOLT_DYLIB=$(find "$BUILD_DIR_DEVICE" -name "libJolt.dylib" -type f | head -n 1)

if [ -z "$JOLTC_DYLIB" ]; then
    echo "Error: joltc dylib not found"
    echo "Searching in: $BUILD_DIR_DEVICE"
    find "$BUILD_DIR_DEVICE" -name "libjoltc*" -type f
    exit 1
fi

if [ -z "$JOLT_DYLIB" ]; then
    echo "Error: Jolt dylib not found"
    echo "Searching in: $BUILD_DIR_DEVICE"
    find "$BUILD_DIR_DEVICE" -name "libJolt*" -type f
    exit 1
fi

echo "Found joltc library: $JOLTC_DYLIB"
echo "Found Jolt library: $JOLT_DYLIB"

# Create framework structures
echo ""
echo "Creating framework structures..."
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
DEST_DIR="$JOLTC_DIR/libs/ios/$BUILD_TYPE_LOWER"
mkdir -p "$DEST_DIR"

# Create joltc.framework
JOLTC_FRAMEWORK_PATH="$DEST_DIR/joltc.framework"
rm -rf "$JOLTC_FRAMEWORK_PATH"
mkdir -p "$JOLTC_FRAMEWORK_PATH/Headers"

# Copy the joltc dylib as framework binary
cp "$JOLTC_DYLIB" "$JOLTC_FRAMEWORK_PATH/joltc"

# Fix the install name to use framework path instead of dylib path
install_name_tool -id "@rpath/joltc.framework/joltc" "$JOLTC_FRAMEWORK_PATH/joltc"

# Create Jolt.framework
JOLT_FRAMEWORK_PATH="$DEST_DIR/Jolt.framework"
rm -rf "$JOLT_FRAMEWORK_PATH"
mkdir -p "$JOLT_FRAMEWORK_PATH/Headers"

# Copy the Jolt dylib as framework binary
cp "$JOLT_DYLIB" "$JOLT_FRAMEWORK_PATH/Jolt"

# Fix the install name to use framework path instead of dylib path
install_name_tool -id "@rpath/Jolt.framework/Jolt" "$JOLT_FRAMEWORK_PATH/Jolt"

# Copy headers for joltc
if [ -d "$JOLTC_DIR/include" ]; then
    cp -R "$JOLTC_DIR/include/"* "$JOLTC_FRAMEWORK_PATH/Headers/"
fi

# Create Info.plist for joltc.framework
cat > "$JOLTC_FRAMEWORK_PATH/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>joltc</string>
    <key>CFBundleIdentifier</key>
    <string>com.joltphysics.joltc</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>joltc</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

# Create Info.plist for Jolt.framework
cat > "$JOLT_FRAMEWORK_PATH/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Jolt</string>
    <key>CFBundleIdentifier</key>
    <string>com.joltphysics.jolt</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Jolt</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

echo "=========================================="
echo "Updating joltc framework to use Jolt.framework..."
echo "=========================================="

# Update joltc's dependency to reference Jolt.framework instead of libJolt.dylib
install_name_tool -change "@rpath/libJolt.dylib" "@rpath/Jolt.framework/Jolt" "$JOLTC_FRAMEWORK_PATH/joltc"

if [ $? -ne 0 ]; then
    echo "✗ Failed to update joltc framework dependency"
    exit 1
fi

echo "✓ Updated joltc to reference Jolt.framework/Jolt"

echo "=========================================="
echo "Build complete!"
echo "Output: $DEST_DIR"
echo "=========================================="

# Verify the frameworks were created
if [ -d "$JOLTC_FRAMEWORK_PATH" ] && [ -f "$JOLTC_FRAMEWORK_PATH/joltc" ]; then
    echo "✓ Successfully built joltc.framework for iOS (device)"
    echo ""
    echo "joltc.framework info:"
    ls -lh "$JOLTC_FRAMEWORK_PATH/joltc"
    file "$JOLTC_FRAMEWORK_PATH/joltc"
else
    echo "✗ Failed to build joltc.framework"
    exit 1
fi

if [ -d "$JOLT_FRAMEWORK_PATH" ] && [ -f "$JOLT_FRAMEWORK_PATH/Jolt" ]; then
    echo "✓ Successfully built Jolt.framework for iOS (device)"
    echo ""
    echo "Jolt.framework info:"
    ls -lh "$JOLT_FRAMEWORK_PATH/Jolt"
    file "$JOLT_FRAMEWORK_PATH/Jolt"
else
    echo "✗ Failed to build Jolt.framework"
    exit 1
fi
