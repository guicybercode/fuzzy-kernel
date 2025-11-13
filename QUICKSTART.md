# Quick Start Guide

Get the Microkernel IoT Platform running in 5 minutes!

## Prerequisites Check

```bash
zig version          # Should be 0.11+
elixir --version     # Should be 1.14+
docker --version     # Any recent version
```

## Step 1: Start Infrastructure (2 minutes)

```bash
make infra-up
```

Wait for services to initialize. You should see:
- ✅ EMQ X Dashboard: http://localhost:18083 (admin/public)
- ✅ PostgreSQL: localhost:5432

## Step 2: Start Server (2 minutes)

```bash
make server-setup
make server-start
```

Open browser: http://localhost:4000

You should see the IoT Dashboard (currently empty, waiting for devices).

## Step 3: Start Edge Device (1 minute)

In a new terminal:

```bash
export DEVICE_ID=device-001
export MQTT_BROKER_HOST=localhost
export MQTT_BROKER_PORT=1883

make edge-run
```

## See It Working!

1. Watch the edge device terminal - you'll see sensor readings every 5 seconds:
   ```
   [timestamp] Temperature: 23.45 °C
   [timestamp] Humidity: 65.23 %
   [timestamp] Motion: 0.00 bool
   ```

2. Refresh the dashboard at http://localhost:4000
   - You should now see "device-001" online
   - Click on the device to see real-time telemetry
   - Watch for anomaly detection alerts (⚠️)

## What's Happening?

```
Edge Device (Zig)
    ↓ reads sensors every 5s
    ↓ runs TinyML anomaly detection
    ↓ publishes to MQTT
    ↓
EMQ X Broker
    ↓
Elixir Server
    ↓ updates device registry
    ↓ broadcasts via PubSub
    ↓
LiveView Dashboard
    ↓ shows real-time updates
```

## Next Steps

1. **Add More Devices**: Run `make edge-run` with different `DEVICE_ID`
2. **Test OTA Updates**: Open IEx console and run:
   ```elixir
   Microkernel.OTA.Updater.register_update("1.0.1", "https://example.com/fw.bin", "sha256:abc123", "Bug fixes")
   Microkernel.OTA.Updater.deploy_update("device-001", "1.0.1")
   ```
3. **View Device Details**: Click on a device in the dashboard
4. **Monitor EMQ X**: Visit http://localhost:18083 to see MQTT traffic

## Troubleshooting

**Problem**: Server won't start
```bash
docker-compose ps                    # Check if PostgreSQL is running
cd server && mix deps.get            # Reinstall dependencies
```

**Problem**: Edge device can't connect
```bash
docker logs microkernel-emqx         # Check EMQ X logs
telnet localhost 1883                # Test MQTT port
```

**Problem**: No devices showing in dashboard
```bash
docker exec -it microkernel-emqx emqx ctl clients list    # Check connected clients
```

## Clean Up

```bash
make infra-down                      # Stop infrastructure
make clean                           # Clean build artifacts
```

## Full Documentation

See [README.md](README.md) for complete documentation.

