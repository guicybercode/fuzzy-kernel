#!/bin/bash

set -e

echo "🔧 Installing dependencies for Arch Linux..."

echo "📦 Installing system packages..."
sudo pacman -S --needed \
    zig \
    elixir \
    erlang \
    postgresql \
    docker \
    docker-compose \
    nodejs \
    npm \
    git \
    make \
    gcc \
    pkg-config \
    mbedtls \
    openssl

echo "📦 Installing Zig dependencies (mbedTLS, wasmtime, TensorFlow Lite)..."
echo "⚠️  Note: These libraries need to be compiled manually or installed via AUR"

echo "✅ System dependencies installed!"
echo ""
echo "To compile the required C libraries:"
echo "  - mbedTLS: https://github.com/Mbed-TLS/mbedtls"
echo "  - wasmtime: https://github.com/bytecodealliance/wasmtime"
echo "  - TensorFlow Lite: https://www.tensorflow.org/lite/guide/build_cmake"

