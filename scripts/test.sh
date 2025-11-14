#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧪 Running tests..."

echo "📦 Testing server (Elixir)..."
cd server

echo "  Running unit tests..."
mix test || {
    echo "  ⚠️  Some tests failed"
    exit 1
}

echo "  Running code quality checks..."
mix credo --strict || echo "  ⚠️  Code quality issues found (non-blocking)"

echo "  Running dialyzer..."
mix dialyzer || echo "  ⚠️  Dialyzer issues found (non-blocking)"

cd ..

echo ""
echo "✅ All tests passed!"

