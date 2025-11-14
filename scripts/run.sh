#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Iniciando Microkernel IoT Platform..."

check_service() {
    if ! docker ps | grep -q "$1"; then
        echo "⚠️  Serviço $1 não está rodando. Iniciando..."
        docker-compose up -d "$1"
        sleep 3
    fi
}

echo "🐳 Verificando serviços Docker..."
check_service "postgres"
check_service "emqx"

echo "📦 Verificando dependências do servidor..."
cd server

if [ ! -d "deps" ]; then
    echo "  Instalando dependências..."
    mix deps.get
fi

if ! mix ecto.migrate --quiet 2>/dev/null; then
    echo "  Aplicando migrations..."
    mix ecto.migrate
fi

echo "🔧 Compilando servidor..."
mix compile

echo "🌐 Iniciando servidor Phoenix..."
echo "  Acesse: http://localhost:4000"
echo "  Login: /login"
echo ""
echo "  Para parar: Ctrl+C"
echo ""

mix phx.server

