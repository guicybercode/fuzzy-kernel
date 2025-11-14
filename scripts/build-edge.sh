#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/edge"

echo "🔨 Compilando edge device (Zig)..."

TARGET="${1:-arm-linux-gnueabihf}"

echo "  Target: $TARGET"
echo ""

zig build -Dtarget=$TARGET || {
    echo ""
    echo "⚠️  Compilação falhou!"
    echo ""
    echo "Possíveis causas:"
    echo "  1. Bibliotecas C não instaladas (mbedTLS, wasmtime, TensorFlow Lite)"
    echo "  2. Target não suportado"
    echo ""
    echo "Para compilar sem as bibliotecas C (modo básico):"
    echo "  zig build -Dtarget=$TARGET -Dskip-tls -Dskip-wasm -Dskip-tinyml"
    exit 1
}

echo ""
echo "✅ Edge compilado com sucesso!"
echo "  Binário: $PROJECT_ROOT/edge/zig-out/bin/microkernel-edge"

