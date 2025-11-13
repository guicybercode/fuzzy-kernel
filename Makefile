.PHONY: help infra-up infra-down server-setup server-start edge-build edge-run clean

help:
	@echo "Microkernel IoT Platform - Make Commands"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make infra-up       - Start Docker infrastructure (EMQ X + PostgreSQL)"
	@echo "  make infra-down     - Stop Docker infrastructure"
	@echo ""
	@echo "Server (Elixir):"
	@echo "  make server-setup   - Setup server dependencies and database"
	@echo "  make server-start   - Start Phoenix server"
	@echo ""
	@echo "Edge (Zig):"
	@echo "  make edge-build     - Build edge firmware (native)"
	@echo "  make edge-build-arm - Build edge firmware for ARM (Raspberry Pi)"
	@echo "  make edge-run       - Run edge daemon"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Clean build artifacts"

infra-up:
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 5
	@echo "Infrastructure is ready!"
	@echo "EMQ X Dashboard: http://localhost:18083 (admin/public)"
	@echo "PostgreSQL: localhost:5432"

infra-down:
	docker-compose down

server-setup:
	cd server && mix deps.get && mix ecto.create && mix ecto.migrate

server-start:
	cd server && mix phx.server

edge-build:
	cd edge && zig build

edge-build-arm:
	cd edge && zig build -Dtarget=arm-linux-gnueabihf -Doptimize=ReleaseSafe

edge-run:
	cd edge && zig build run

clean:
	cd edge && rm -rf zig-cache zig-out
	cd server && rm -rf _build deps

