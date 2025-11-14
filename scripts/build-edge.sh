#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/edge"

echo "🔨 Building edge device (Zig)..."

# Auto-detect target if not provided
if [ -z "$1" ]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        armv7l|armv6l)
            TARGET="arm-linux-gnueabihf"
            echo "  Auto-detected: ARMv7 (Raspberry Pi 2/3/Zero)"
            ;;
        aarch64)
            TARGET="aarch64-linux-gnu"
            echo "  Auto-detected: ARM64 (Raspberry Pi 4/5)"
            ;;
        x86_64)
            TARGET="x86_64-linux-gnu"
            echo "  Auto-detected: x86_64 (cross-compilation)"
            ;;
        *)
            TARGET="arm-linux-gnueabihf"
            echo "  Default target: arm-linux-gnueabihf"
            ;;
    esac
else
    TARGET="$1"
fi

echo "  Target: $TARGET"
echo ""

zig build -Dtarget=$TARGET || {
    echo ""
    echo "⚠️  Build failed!"
    echo ""
    echo "Possible causes:"
    echo "  1. C libraries not installed (mbedTLS, wasmtime, TensorFlow Lite)"
    echo "  2. Target not supported"
    echo ""
    echo "To build without C libraries (basic mode):"
    echo "  zig build -Dtarget=$TARGET -Dskip-tls -Dskip-wasm -Dskip-tinyml"
    exit 1
}

echo ""
echo "✅ Edge built successfully!"
echo "  Binary: $PROJECT_ROOT/edge/zig-out/bin/microkernel-edge"

