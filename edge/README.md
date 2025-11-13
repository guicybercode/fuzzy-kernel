# Edge Firmware (Zig)

This directory contains the Zig-based firmware for IoT edge devices (Raspberry Pi).

## Features

- Generic sensor abstraction (temperature, humidity, motion)
- MQTT client with TLS encryption
- CoAP protocol support
- Local cache with disk persistence
- WebAssembly runtime for edge scripts
- TinyML inference engine for anomaly detection
- Automatic reconnection with exponential backoff

## Building

### For local development (native):
```bash
zig build
```

### For Raspberry Pi (ARMv7):
```bash
zig build -Dtarget=arm-linux-gnueabihf -Doptimize=ReleaseSafe
```

### Run locally:
```bash
zig build run
```

## Configuration

Set environment variables:
```bash
export DEVICE_ID=device-001
export MQTT_BROKER_HOST=localhost
export MQTT_BROKER_PORT=1883
```

## Deployment

Copy to Raspberry Pi:
```bash
scp zig-out/bin/microkernel-edge pi@raspberrypi.local:/home/pi/
```

Run on device:
```bash
ssh pi@raspberrypi.local
chmod +x microkernel-edge
./microkernel-edge
```

## Architecture

```
main.zig
├── mqtt_client.zig   - MQTT communication
├── coap_client.zig   - CoAP protocol
├── sensors.zig       - Sensor abstraction
├── cache.zig         - Local caching
├── wasm_runtime.zig  - WASM execution
├── tinyml.zig        - ML inference
└── tls.zig           - TLS encryption
```

