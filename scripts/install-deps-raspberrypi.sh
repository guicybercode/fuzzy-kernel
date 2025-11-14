#!/bin/bash

set -e

echo "🔧 Installing dependencies for Raspberry Pi..."

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi"
    echo "   Continuing anyway..."
fi

echo "📦 Updating package list..."
sudo apt-get update

echo "📦 Installing system packages..."
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    pkg-config \
    libssl-dev \
    libmbedtls-dev \
    python3 \
    python3-pip \
    i2c-tools \
    libi2c-dev \
    spi-tools \
    libgpiod-dev \
    postgresql-client \
    docker.io \
    docker-compose

echo "📦 Installing Node.js and npm..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "  Node.js already installed"
fi

echo "📦 Installing Zig..."
if ! command -v zig &> /dev/null; then
    echo "  Downloading Zig for ARM..."
    ZIG_VERSION="0.12.0"
    ZIG_ARCH="aarch64-linux"
    
    # Check architecture
    if [ "$(uname -m)" = "armv7l" ]; then
        ZIG_ARCH="armv7a-linux"
    fi
    
    cd /tmp
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    sudo mv "zig-${ZIG_ARCH}-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm -f "zig-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    echo "  Zig installed to /opt/zig"
else
    echo "  Zig already installed"
fi

echo "📦 Installing Elixir and Erlang..."
if ! command -v elixir &> /dev/null; then
    echo "  Installing Erlang/OTP and Elixir..."
    sudo apt-get install -y \
        erlang \
        elixir
else
    echo "  Elixir already installed"
fi

echo "📦 Enabling I2C and SPI interfaces..."
if [ -f /boot/config.txt ]; then
    if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
        echo "  Enabling I2C..."
        echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt
    fi
    
    if ! grep -q "^dtparam=spi=on" /boot/config.txt; then
        echo "  Enabling SPI..."
        echo "dtparam=spi=on" | sudo tee -a /boot/config.txt
    fi
    
    echo "  ⚠️  Reboot required for I2C/SPI changes to take effect"
else
    echo "  ⚠️  /boot/config.txt not found (may not be running on Raspberry Pi OS)"
fi

echo "📦 Installing Python libraries for sensor development..."
pip3 install --user \
    RPi.GPIO \
    adafruit-circuitpython-i2c \
    adafruit-circuitpython-spi || echo "  ⚠️  Some Python packages may have failed (non-critical)"

echo "📦 Installing Zig dependencies (mbedTLS, wasmtime, TensorFlow Lite)..."
echo "⚠️  Note: These libraries need to be compiled manually for ARM"
echo ""
echo "To compile the required C libraries:"
echo "  - mbedTLS: https://github.com/Mbed-TLS/mbedtls"
echo "  - wasmtime: https://github.com/bytecodealliance/wasmtime"
echo "  - TensorFlow Lite: https://www.tensorflow.org/lite/guide/build_cmake"

echo ""
echo "✅ System dependencies installed!"
echo ""
echo "📝 Next steps:"
echo "  1. Reboot if I2C/SPI was enabled: sudo reboot"
echo "  2. Run setup script: ./scripts/setup.sh"
echo "  3. Build edge for Raspberry Pi: ./scripts/build-edge.sh arm-linux-gnueabihf"

