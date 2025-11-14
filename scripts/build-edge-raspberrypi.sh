#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/edge"

echo "🔨 Building edge device for Raspberry Pi (native build)..."

# Detect Raspberry Pi architecture
ARCH=$(uname -m)
case "$ARCH" in
    armv7l)
        TARGET="arm-linux-gnueabihf"
        echo "  Detected: ARMv7 (Raspberry Pi 2/3/Zero)"
        ;;
    aarch64)
        TARGET="aarch64-linux-gnu"
        echo "  Detected: ARM64 (Raspberry Pi 4/5)"
        ;;
    *)
        TARGET="arm-linux-gnueabihf"
        echo "  ⚠️  Unknown architecture, defaulting to arm-linux-gnueabihf"
        ;;
esac

echo "  Target: $TARGET"
echo "  Building natively on Raspberry Pi..."
echo ""

zig build -Dtarget=$TARGET || {
    echo ""
    echo "⚠️  Build failed!"
    echo ""
    echo "Possible causes:"
    echo "  1. C libraries not installed (mbedTLS, wasmtime, TensorFlow Lite)"
    echo "  2. Insufficient memory (try: sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon)"
    echo "  3. Missing system dependencies"
    echo ""
    echo "To build without C libraries (basic mode):"
    echo "  zig build -Dtarget=$TARGET -Dskip-tls -Dskip-wasm -Dskip-tinyml"
    exit 1
}

echo ""
echo "✅ Edge built successfully!"
echo "  Binary: $PROJECT_ROOT/edge/zig-out/bin/microkernel-edge"
echo ""
echo "To run on this Raspberry Pi:"
echo "  sudo $PROJECT_ROOT/edge/zig-out/bin/microkernel-edge"

