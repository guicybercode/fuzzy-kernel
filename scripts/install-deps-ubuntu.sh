#!/bin/bash

set -e

echo "🔧 Installing dependencies for Ubuntu/Debian..."

echo "📦 Updating packages..."
sudo apt-get update

echo "📦 Installing system packages..."
sudo apt-get install -y \
    zig \
    elixir \
    erlang \
    postgresql \
    docker.io \
    docker-compose \
    nodejs \
    npm \
    git \
    build-essential \
    pkg-config \
    libmbedtls-dev \
    libssl-dev \
    curl

echo "📦 Installing Zig dependencies (mbedTLS, wasmtime, TensorFlow Lite)..."
echo "⚠️  Note: These libraries need to be compiled manually"

echo "✅ System dependencies installed!"
echo ""
echo "To compile the required C libraries:"
echo "  - mbedTLS: https://github.com/Mbed-TLS/mbedtls"
echo "  - wasmtime: https://github.com/bytecodealliance/wasmtime"
echo "  - TensorFlow Lite: https://www.tensorflow.org/lite/guide/build_cmake"

