# Distributed IoT Microkernel Platform

A high-performance, distributed IoT platform combining Zig for edge computing and Elixir for server orchestration. This platform enables real-time sensor data collection, WebAssembly-based edge scripting, TinyML anomaly detection, and Over-The-Air (OTA) firmware updates.

![Platform Architecture](docs/architecture-diagram.png)

## Architecture Overview

### Edge Layer (Zig)
The edge firmware runs on Raspberry Pi devices and provides:
- **Real-time Sensor Integration**: Temperature, humidity, and motion sensors
- **MQTT/CoAP Communication**: Secure, TLS-encrypted data transmission
- **Local Cache**: Offline operation with automatic synchronization
- **WebAssembly Runtime**: Execute custom scripts on edge devices
- **TinyML Engine**: Local anomaly detection and failure prediction
- **Auto-Reconnection**: Network resilience with exponential backoff

### Server Layer (Elixir)
The control server orchestrates all devices through:
- **Phoenix LiveView Dashboard**: Real-time device monitoring and visualization
- **EMQ X MQTT Broker**: Scalable message routing and device communication
- **Device Registry**: Centralized device management and health monitoring
- **OTA Update System**: Version-controlled firmware distribution
- **Telemetry Collection**: Real-time data aggregation and broadcasting

### Communication Protocol
```
Edge Device (Zig) ←→ MQTT/TLS ←→ EMQ X Broker ←→ Elixir Server ←→ LiveView Dashboard
       ↓                                                    ↓
  Local Cache                                      PostgreSQL Database
       ↓
  WASM Scripts
       ↓
  TinyML Model
```

## Features

### Edge Features
- ✅ Cross-compiled for ARMv7 (Raspberry Pi)
- ✅ Generic sensor abstraction layer
- ✅ MQTT client with QoS support
- ✅ CoAP protocol implementation
- ✅ TLS/DTLS encryption
- ✅ Persistent local cache
- ✅ WebAssembly runtime for edge scripting
- ✅ TinyML anomaly detection
- ✅ Automatic reconnection with exponential backoff

### Server Features
- ✅ Phoenix LiveView real-time dashboard
- ✅ Device registration and authentication
- ✅ Real-time telemetry visualization
- ✅ OTA firmware update management
- ✅ Device health monitoring
- ✅ Historical data tracking
- ✅ EMQ X MQTT broker integration
- ✅ PostgreSQL database persistence

## Quick Start

### Prerequisites
- Zig 0.11+ (for edge firmware)
- Elixir 1.14+ and Erlang/OTP 25+
- Docker and Docker Compose
- Raspberry Pi (ARMv7) for edge deployment

### Infrastructure Setup

1. **Start the infrastructure** (EMQ X MQTT broker and PostgreSQL):
```bash
docker-compose up -d
```

2. **Verify services are running**:
```bash
docker-compose ps
```

EMQ X Dashboard: http://localhost:18083 (admin/public)
PostgreSQL: localhost:5432

### Server Setup

1. **Navigate to server directory**:
```bash
cd server
```

2. **Install dependencies**:
```bash
mix deps.get
```

3. **Create and migrate database**:
```bash
mix ecto.create
mix ecto.migrate
```

4. **Install Node.js dependencies for assets**:
```bash
cd assets && npm install && cd ..
```

5. **Start the Phoenix server**:
```bash
mix phx.server
```

Server runs at: http://localhost:4000

### Edge Firmware Setup

1. **Navigate to edge directory**:
```bash
cd edge
```

2. **Build for Raspberry Pi** (ARMv7):
```bash
zig build -Dtarget=arm-linux-gnueabihf -Doptimize=ReleaseSafe
```

3. **Build for local development** (native):
```bash
zig build
```

4. **Configure environment variables**:
```bash
export DEVICE_ID=device-001
export MQTT_BROKER_HOST=localhost
export MQTT_BROKER_PORT=1883
```

5. **Run the edge daemon**:
```bash
zig build run
```

### Cross-Compilation for Raspberry Pi

To deploy on Raspberry Pi:

```bash
cd edge
zig build -Dtarget=arm-linux-gnueabihf -Doptimize=ReleaseSafe
scp zig-out/bin/microkernel-edge pi@raspberrypi.local:/home/pi/
```

On the Raspberry Pi:
```bash
chmod +x microkernel-edge
./microkernel-edge
```

## Project Structure

```
microkernel/
├── edge/                       # Zig edge firmware
│   ├── build.zig              # Build system with ARM cross-compilation
│   ├── config/
│   │   └── config.zig         # Configuration management
│   └── src/
│       ├── main.zig           # Main daemon entry point
│       ├── mqtt_client.zig    # MQTT client with TLS
│       ├── coap_client.zig    # CoAP protocol implementation
│       ├── sensors.zig        # Generic sensor abstraction
│       ├── wasm_runtime.zig   # WebAssembly runtime
│       ├── tinyml.zig         # TinyML inference engine
│       ├── cache.zig          # Local cache with persistence
│       └── tls.zig            # TLS implementation
├── server/                     # Elixir control server
│   ├── mix.exs                # Project dependencies
│   ├── config/                # Application configuration
│   ├── lib/
│   │   ├── microkernel/
│   │   │   ├── application.ex      # OTP application
│   │   │   ├── repo.ex             # Ecto repository
│   │   │   ├── mqtt/
│   │   │   │   ├── subscriber.ex   # MQTT message handler
│   │   │   │   └── publisher.ex    # Command publisher
│   │   │   ├── devices/
│   │   │   │   ├── device.ex       # Device schema
│   │   │   │   ├── registry.ex     # Device registry
│   │   │   │   └── supervisor.ex   # Device supervision
│   │   │   ├── ota/
│   │   │   │   └── updater.ex      # OTA update manager
│   │   │   └── telemetry.ex        # Telemetry collection
│   │   └── microkernel_web/
│   │       ├── endpoint.ex         # Phoenix endpoint
│   │       ├── router.ex           # Routes
│   │       └── live/
│   │           ├── device_live/
│   │           │   ├── index.ex    # Device list dashboard
│   │           │   └── show.ex     # Device detail view
│   │           └── components/     # Reusable components
│   └── priv/
│       └── repo/
│           └── migrations/         # Database migrations
├── docker-compose.yml          # Infrastructure orchestration
└── README.md                   # This file
```

## Configuration

### Edge Device Configuration

Environment variables for edge devices:

```bash
DEVICE_ID=device-001              # Unique device identifier
MQTT_BROKER_HOST=localhost         # MQTT broker hostname
MQTT_BROKER_PORT=1883              # MQTT broker port
MQTT_CA_CERT=/path/to/ca.crt      # CA certificate (optional)
MQTT_CLIENT_CERT=/path/to/client.crt  # Client certificate (optional)
MQTT_CLIENT_KEY=/path/to/client.key   # Client key (optional)
```

### Server Configuration

Edit `server/config/dev.exs` for development settings:

```elixir
config :microkernel, :mqtt,
  host: "localhost",
  port: 1883,
  client_id: "microkernel_server"

config :microkernel, Microkernel.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "microkernel_dev",
  pool_size: 10
```

## MQTT Topics

### Telemetry (Device → Server)
```
devices/{device_id}/telemetry
```

Payload:
```json
{
  "device_id": "device-001",
  "sensor": "Temperature",
  "value": 23.5,
  "unit": "°C",
  "timestamp": 1704067200,
  "anomaly": false,
  "confidence": 0.95
}
```

### Commands (Server → Device)
```
devices/{device_id}/commands
```

Payload:
```json
{
  "command": "update",
  "payload": {
    "version": "1.0.0"
  },
  "timestamp": 1704067200
}
```

## Dashboard

The LiveView dashboard provides real-time monitoring:

![Dashboard Screenshot](docs/dashboard-screenshot.png)

### Features
- Real-time device status
- Live telemetry updates
- Anomaly detection alerts
- Device control actions
- Firmware update management
- Historical data visualization

## OTA Updates

Register and deploy firmware updates:

```elixir
# In IEx console
Microkernel.OTA.Updater.register_update(
  "1.0.1",
  "https://example.com/firmware/1.0.1.bin",
  "sha256:abcd1234...",
  "Bug fixes and improvements"
)

Microkernel.OTA.Updater.deploy_update("device-001", "1.0.1")
```

## WebAssembly Support

Load and execute WebAssembly modules on edge devices:

```zig
const wasm_runtime = try wasm.WasmRuntime.init(allocator);
try wasm_runtime.loadModule("sensor_filter", "/path/to/filter.wasm");

const result = try wasm_runtime.processSensorData(
    "sensor_filter",
    "filter_temperature",
    temperature_value
);
```

## TinyML Anomaly Detection

The edge devices include a TinyML engine for local inference:

```zig
const ml_engine = try tinyml.TinyMLEngine.init(allocator);
try ml_engine.loadModel(
    "anomaly_detector",
    "/var/lib/microkernel/models/anomaly.bin",
    .AnomalyDetection
);

const result = try ml_engine.predictAnomaly("anomaly_detector", sensor_value);
if (result.anomaly_detected) {
    // Handle anomaly
}
```

## Development

### Running Tests

Edge (Zig):
```bash
cd edge
zig build test
```

Server (Elixir):
```bash
cd server
mix test
```

### Code Formatting

Edge (Zig):
```bash
zig fmt src/
```

Server (Elixir):
```bash
mix format
```

## Performance

- **Edge Latency**: < 10ms sensor reading to MQTT publish
- **Network Resilience**: Automatic reconnection with exponential backoff (1s - 60s)
- **Cache Capacity**: 1000 entries with disk persistence
- **MQTT QoS**: Supports QoS 0, 1, and 2
- **Server Throughput**: 10,000+ messages/second (EMQ X)
- **LiveView Updates**: Real-time with Phoenix PubSub

## Security

- TLS 1.3 encryption for MQTT connections
- DTLS for CoAP connections
- Device authentication via client certificates
- CSRF protection on web interface
- Secure session management

## Roadmap

- [x] Basic MQTT communication
- [x] Sensor abstraction layer
- [x] WebAssembly runtime
- [x] TinyML inference
- [x] LiveView dashboard
- [x] OTA updates
- [ ] Multi-region deployment
- [ ] Advanced analytics
- [ ] Mobile app
- [ ] REST API

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

For questions and support, please open an issue on GitHub.

---

**성경 구절 (聖經 句節)**

> 너희는 먼저 그의 나라와 그의 의를 구하라 그리하면 이 모든 것을 너희에게 더하시리라
> 
> *마태복음 6:33*
> 
> *But seek first his kingdom and his righteousness, and all these things will be given to you as well.*
> 
> *Matthew 6:33*

