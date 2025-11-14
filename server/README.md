# Microkernel Server

Elixir/Phoenix control server for the Distributed IoT Microkernel Platform.

## Quick Start

```bash
mix setup
mix phx.server
```

## Features

- Phoenix LiveView real-time dashboard
- EMQ X MQTT broker integration
- Device registry and health monitoring
- OTA firmware updates with Oban jobs
- Real-time telemetry visualization
- PostgreSQL database persistence

## Development

### Setup

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix assets.setup
```

### Testing

```bash
mix test
mix test.watch
```

### Code Quality

```bash
mix quality          # Runs credo, dialyzer, and tests
mix credo            # Static analysis
mix dialyzer         # Type checking
mix format           # Format code
mix format.check     # Check formatting
```

### Documentation

```bash
mix docs             # Generate HTML docs
mix docs --open      # Open in browser
```

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
│   ├── ota/
│   │   └── updater.ex     - OTA update system
│   └── jobs/
│       ├── ota_job.ex     - OTA background job
│       └── health_check_job.ex - Device health check
└── microkernel_web/
    ├── endpoint.ex        - Phoenix endpoint
    ├── router.ex          - Routes
    └── live/
        └── device_live/   - LiveView pages
```

## Configuration

Environment variables:
- `DATABASE_URL` - PostgreSQL connection URL
- `MQTT_HOST` - MQTT broker hostname
- `MQTT_PORT` - MQTT broker port
- `SECRET_KEY_BASE` - Phoenix secret key

## Oban Jobs

Background jobs are configured in `config/config.exs`:

- `ota` queue - Firmware update jobs
- `telemetry` queue - Telemetry processing
- `default` queue - General jobs

## License

MIT
