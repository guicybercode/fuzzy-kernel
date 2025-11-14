#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧹 Cleaning project..."

read -p "This will remove build artifacts, dependencies, and database. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "📦 Cleaning server..."
cd server
rm -rf _build deps .elixir_ls priv/static/assets node_modules
mix clean || true
cd ..

echo "📦 Cleaning edge..."
cd edge
rm -rf zig-cache zig-out
cd ..

echo "🐳 Stopping Docker services..."
docker-compose down -v || echo "  Docker services not running"

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "To start fresh:"
echo "  ./scripts/setup.sh"

