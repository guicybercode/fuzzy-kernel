#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/edge"

echo "🔨 Building edge device (Zig)..."

TARGET="${1:-arm-linux-gnueabihf}"

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

