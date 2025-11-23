# Build script for joltc library on Windows
# Usage: .\build-joltc-windows.ps1 [-Architecture <arch>] [-BuildType <type>]
# Example: .\build-joltc-windows.ps1 -Architecture x64 -BuildType Release
# Example: .\build-joltc-windows.ps1 -Architecture Win32 -BuildType Debug
# Architectures: x64, Win32, ARM64

param(
    [string]$Architecture = "x64",
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$JoltcDir = Join-Path $ScriptDir ".."
$BuildDir = Join-Path $JoltcDir "build-windows-$Architecture"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building joltc for Windows" -ForegroundColor Cyan
Write-Host "Architecture: $Architecture" -ForegroundColor Cyan
Write-Host "Build Type: $BuildType" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Create build directory
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Set-Location $BuildDir

# Configure with CMake
Write-Host "Configuring CMake..." -ForegroundColor Yellow
cmake .. `
    -G "Visual Studio 17 2022" `
    -A $Architecture `
    -DCMAKE_BUILD_TYPE="$BuildType" `
    -DBUILD_SHARED_LIBS=ON `
    -DTARGET_UNIT_TESTS=OFF `
    -DTARGET_HELLO_WORLD=OFF `
    -DTARGET_PERFORMANCE_TEST=OFF `
    -DTARGET_SAMPLES=OFF `
    -DTARGET_VIEWER=OFF `
    -DENABLE_ALL_WARNINGS=OFF `
    -DTARGET_01_HELLOWORLD=OFF `
    -DENABLE_SAMPLES=OFF

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ CMake configuration failed" -ForegroundColor Red
    exit 1
}

# Build only joltc target (not samples)
Write-Host "Building joltc target only..." -ForegroundColor Yellow
cmake --build . --config $BuildType --target joltc

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}

# Create destination directory
$BuildTypeLower = $BuildType.ToLower()
$DestDir = Join-Path $JoltcDir "libs\windows\$Architecture\$BuildTypeLower"
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

# Copy library to destination
Write-Host "Copying library to $DestDir..." -ForegroundColor Yellow

# Search for joltc DLL
$DllPath = Get-ChildItem -Path "$BuildDir\bin\$BuildType" -Filter "joltc*.dll" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if (-not $DllPath) {
    # Try alternative location
    $DllPath = Get-ChildItem -Path "$BuildDir\$BuildType\bin" -Filter "joltc*.dll" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}

if (-not $DllPath) {
    # Try root build directory
    $DllPath = Get-ChildItem -Path "$BuildDir\$BuildType" -Filter "joltc*.dll" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}

if ($DllPath -and (Test-Path $DllPath)) {
    Copy-Item "$DllPath" "$DestDir\joltc.dll"
    Write-Host "  Copied: $(Split-Path $DllPath -Leaf) -> joltc.dll" -ForegroundColor Green
    
    # Also copy lib file if it exists
    $LibDir = Split-Path $DllPath -Parent
    $LibPath = Get-ChildItem -Path "$LibDir" -Filter "joltc*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if (-not $LibPath) {
        # Try lib subdirectory
        $LibPath = Get-ChildItem -Path "$BuildDir\lib\$BuildType" -Filter "joltc*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
    if ($LibPath -and (Test-Path $LibPath)) {
        Copy-Item "$LibPath" "$DestDir\joltc.lib"
        Write-Host "  Copied: $(Split-Path $LibPath -Leaf) -> joltc.lib" -ForegroundColor Green
    }
    
    # Also copy Jolt.dll dependency
    $JoltDllPath = Get-ChildItem -Path "$LibDir" -Filter "Jolt.dll" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if (-not $JoltDllPath) {
        # Try lib subdirectory
        $JoltDllPath = Get-ChildItem -Path "$BuildDir\lib\$BuildType" -Filter "Jolt.dll" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
    if ($JoltDllPath -and (Test-Path $JoltDllPath)) {
        Copy-Item "$JoltDllPath" "$DestDir\Jolt.dll"
        Write-Host "  Copied: Jolt.dll" -ForegroundColor Green
    } else {
        Write-Host "  Warning: Jolt.dll not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ joltc DLL not found" -ForegroundColor Red
    Write-Host "Searched paths:" -ForegroundColor Yellow
    Write-Host "  - $BuildDir\bin\$BuildType\joltc*.dll"
    Write-Host "  - $BuildDir\$BuildType\bin\joltc*.dll"
    Write-Host "  - $BuildDir\$BuildType\joltc*.dll"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Output: $DestDir" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

# Verify the library was created
if (Test-Path "$DestDir\joltc.dll") {
    Write-Host "✓ Successfully built joltc.dll" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to build joltc.dll" -ForegroundColor Red
    exit 1
}
