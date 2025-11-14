#!/bin/bash

set -e

echo "🔧 Instalando dependências para Arch Linux..."

echo "📦 Instalando pacotes do sistema..."
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

echo "📦 Instalando dependências Zig (mbedTLS, wasmtime, TensorFlow Lite)..."
echo "⚠️  Nota: Estas bibliotecas precisam ser compiladas manualmente ou instaladas via AUR"

echo "✅ Dependências do sistema instaladas!"
echo ""
echo "Para compilar as bibliotecas C necessárias:"
echo "  - mbedTLS: https://github.com/Mbed-TLS/mbedtls"
echo "  - wasmtime: https://github.com/bytecodealliance/wasmtime"
echo "  - TensorFlow Lite: https://www.tensorflow.org/lite/guide/build_cmake"

