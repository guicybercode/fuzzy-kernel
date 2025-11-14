#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting Microkernel IoT Platform..."

check_service() {
    if ! docker ps | grep -q "$1"; then
        echo "⚠️  Service $1 is not running. Starting..."
        docker-compose up -d "$1"
        sleep 3
    fi
}

echo "🐳 Checking Docker services..."
check_service "postgres"
check_service "emqx"

echo "📦 Checking server dependencies..."
cd server

if [ ! -d "deps" ]; then
    echo "  Installing dependencies..."
    mix deps.get
fi

if ! mix ecto.migrate --quiet 2>/dev/null; then
    echo "  Applying migrations..."
    mix ecto.migrate
fi

echo "🔧 Compiling server..."
mix compile

echo "🌐 Starting Phoenix server..."
echo "  Access: http://localhost:4000"
echo "  Login: /login"
echo ""
echo "  To stop: Ctrl+C"
echo ""

mix phx.server

