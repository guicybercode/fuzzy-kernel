#!/bin/bash

set -e

echo "🔍 Checking prerequisites..."

ERRORS=0

check_command() {
    if command -v "$1" &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -n 1)
        echo "  ✅ $1: $VERSION"
        return 0
    else
        echo "  ❌ $1: NOT FOUND"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_docker() {
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            echo "  ✅ Docker: $(docker --version)"
            return 0
        else
            echo "  ⚠️  Docker: Installed but not running (may need sudo or user in docker group)"
            return 1
        fi
    else
        echo "  ❌ Docker: NOT FOUND"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_service() {
    if docker ps --format '{{.Names}}' | grep -q "^$1$"; then
        echo "  ✅ $1: Running"
        return 0
    else
        echo "  ⚠️  $1: Not running (start with: docker-compose up -d $1)"
        return 1
    fi
}

echo ""
echo "📦 Required tools:"
check_command "zig"
check_command "elixir"
check_command "mix"
check_command "node"
check_command "npm"
check_docker

if command -v docker-compose &> /dev/null; then
    echo "  ✅ docker-compose: $(docker-compose --version)"
else
    echo "  ❌ docker-compose: NOT FOUND"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "🐳 Docker services:"
check_service "microkernel-postgres"
check_service "microkernel-emqx"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All prerequisites met!"
    exit 0
else
    echo "❌ Missing $ERRORS prerequisite(s). Please install them first."
    echo ""
    echo "Installation scripts:"
    echo "  Arch: ./scripts/install-deps-arch.sh"
    echo "  Ubuntu/Debian: ./scripts/install-deps-ubuntu.sh"
    echo "  Raspberry Pi: ./scripts/install-deps-raspberrypi.sh"
    exit 1
fi

