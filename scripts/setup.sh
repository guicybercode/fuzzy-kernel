#!/bin/bash

set -e

echo "🚀 Configurando projeto Microkernel IoT Platform..."

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📦 Configurando servidor (Elixir)..."
cd server

if [ ! -d "deps" ]; then
    echo "  Instalando dependências Elixir..."
    mix deps.get
fi

echo "  Configurando banco de dados..."
mix ecto.create || echo "  Banco já existe ou erro (verifique PostgreSQL)"
mix ecto.migrate || echo "  Migrations já aplicadas"

echo "  Compilando assets..."
mix assets.setup || true
mix assets.build || true

cd ..

echo "📦 Configurando edge (Zig)..."
cd edge

if [ ! -d "zig-cache" ]; then
    echo "  Compilando edge..."
    zig build || echo "  ⚠️  Compilação pode falhar se bibliotecas C não estiverem instaladas"
fi

cd ..

echo "🐳 Iniciando serviços (Docker)..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d || echo "  ⚠️  Docker Compose pode não estar configurado"
else
    echo "  ⚠️  docker-compose não encontrado"
fi

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "Para iniciar o servidor:"
echo "  cd server && mix phx.server"
echo ""
echo "Para compilar o edge:"
echo "  cd edge && zig build"

