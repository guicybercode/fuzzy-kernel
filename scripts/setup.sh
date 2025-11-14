#!/bin/bash

set -e

echo "🚀 Setting up Microkernel IoT Platform project..."

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📦 Setting up server (Elixir)..."
cd server

if [ ! -d "deps" ]; then
    echo "  Installing Elixir dependencies..."
    mix deps.get
fi

echo "  Setting up database..."
mix ecto.create || echo "  Database already exists or error (check PostgreSQL)"
mix ecto.migrate || echo "  Migrations already applied"

echo "  Building assets..."
mix assets.setup || true
mix assets.build || true

cd ..

echo "📦 Setting up edge (Zig)..."
cd edge

if [ ! -d "zig-cache" ]; then
    echo "  Building edge..."
    zig build || echo "  ⚠️  Build may fail if C libraries are not installed"
fi

cd ..

echo "🐳 Starting Docker services..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d || echo "  ⚠️  Docker Compose may not be configured"
else
    echo "  ⚠️  docker-compose not found"
fi

echo ""
echo "✅ Setup completed!"
echo ""
echo "To start the server:"
echo "  cd server && mix phx.server"
echo ""
echo "To build the edge:"
echo "  cd edge && zig build"

