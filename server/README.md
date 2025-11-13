# Server (Elixir/Phoenix)

This directory contains the Elixir-based control server with Phoenix LiveView dashboard.

## Features

- Phoenix LiveView real-time dashboard
- EMQ X MQTT broker integration
- Device registry and management
- OTA firmware updates
- Real-time telemetry visualization
- PostgreSQL database persistence

## Setup

1. Install dependencies:
```bash
mix deps.get
```

2. Create and migrate database:
```bash
mix ecto.create
mix ecto.migrate
```

3. Install Node.js dependencies:
```bash
cd assets && npm install && cd ..
```

4. Start server:
```bash
mix phx.server
```

Server runs at: http://localhost:4000

## Configuration

Edit `config/dev.exs` for development settings.

Environment variables:
- `DATABASE_URL` - PostgreSQL connection URL
- `MQTT_HOST` - MQTT broker hostname
- `MQTT_PORT` - MQTT broker port
- `SECRET_KEY_BASE` - Phoenix secret key

## Architecture

```
lib/
├── microkernel/
│   ├── application.ex     - OTP application
│   ├── repo.ex            - Database repository
│   ├── mqtt/
│   │   ├── subscriber.ex  - MQTT message handler
│   │   └── publisher.ex   - Command publisher
│   ├── devices/
│   │   ├── device.ex      - Device schema
│   │   ├── registry.ex    - Device management
│   │   └── supervisor.ex  - Process supervision
│   └── ota/
│       └── updater.ex     - OTA update system
└── microkernel_web/
    ├── endpoint.ex        - Phoenix endpoint
    ├── router.ex          - Routes
    └── live/
        └── device_live/   - LiveView pages
```

## Testing

```bash
mix test
```

## Production

```bash
MIX_ENV=prod mix do compile, assets.deploy
MIX_ENV=prod mix release
```

