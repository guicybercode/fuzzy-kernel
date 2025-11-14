#!/bin/bash

set -e

echo "🔧 Instalando dependências para Ubuntu/Debian..."

echo "📦 Atualizando pacotes..."
sudo apt-get update

echo "📦 Instalando pacotes do sistema..."
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

echo "📦 Instalando dependências Zig (mbedTLS, wasmtime, TensorFlow Lite)..."
echo "⚠️  Nota: Estas bibliotecas precisam ser compiladas manualmente"

echo "✅ Dependências do sistema instaladas!"
echo ""
echo "Para compilar as bibliotecas C necessárias:"
echo "  - mbedTLS: https://github.com/Mbed-TLS/mbedtls"
echo "  - wasmtime: https://github.com/bytecodealliance/wasmtime"
echo "  - TensorFlow Lite: https://www.tensorflow.org/lite/guide/build_cmake"

