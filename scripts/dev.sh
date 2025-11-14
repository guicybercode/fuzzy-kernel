#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting development environment..."

check_service() {
    if ! docker ps --format '{{.Names}}' | grep -q "^$1$"; then
        echo "  Starting $1..."
        docker-compose up -d "$1"
        sleep 3
    fi
}

echo "🐳 Ensuring Docker services are running..."
check_service "microkernel-postgres"
check_service "microkernel-emqx"

echo "📦 Setting up server for development..."
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

echo ""
echo "🌐 Starting Phoenix server with live reload..."
echo "  Dashboard: http://localhost:4000"
echo "  Login: http://localhost:4000/login"
echo "  API Docs: http://localhost:4000/api/docs"
echo ""
echo "  To stop: Ctrl+C"
echo ""

mix phx.server

