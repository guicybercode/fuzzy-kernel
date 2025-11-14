# Microkernel IoT Platform - API Documentation

## Authentication

All API endpoints require authentication via Bearer token in the Authorization header:

```
Authorization: Bearer YOUR_API_KEY
```

### Creating API Keys

```bash
POST /api/admin/api_keys
Content-Type: application/json

{
  "name": "My API Key"
}
```

Response:
```json
{
  "data": {
    "key": "abc123...",
    "name": "My API Key",
    "message": "Save this key - it will not be shown again"
  }
}
```

## Endpoints

### Devices

#### List Devices
```bash
GET /api/devices
```

Response:
```json
{
  "data": [
    {
      "id": "...",
      "device_id": "device-001",
      "name": "Device 001",
      "status": "online",
      "firmware_version": "1.0.0",
      "last_seen": "2024-01-01T12:00:00Z",
      "metadata": {},
      "inserted_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

#### Get Device
```bash
GET /api/devices/:id
```

### Telemetry

#### Get Telemetry Readings
```bash
GET /api/devices/:device_id/telemetry?limit=100&since=2024-01-01T00:00:00Z&sensor_type=Temperature
```

Query Parameters:
- `limit` (optional, default: 100) - Maximum number of readings
- `since` (optional) - ISO8601 datetime to filter from
- `sensor_type` (optional) - Filter by sensor type

Response:
```json
{
  "data": [
    {
      "id": "...",
      "device_id": "device-001",
      "sensor_type": "Temperature",
      "value": 23.5,
      "unit": "°C",
      "anomaly": false,
      "confidence": 0.95,
      "metadata": {},
      "timestamp": "2024-01-01T12:00:00Z",
      "inserted_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

#### Get Latest Reading
```bash
GET /api/devices/:device_id/telemetry/latest?sensor_type=Temperature
```

Query Parameters:
- `sensor_type` (optional) - Filter by sensor type

### OTA Updates

#### Deploy Update
```bash
POST /api/devices/:device_id/update
Content-Type: application/json

{
  "version": "1.0.1"
}
```

Response:
```json
{
  "data": {
    "device_id": "device-001",
    "version": "1.0.1",
    "status": "pending",
    "package_url": "https://...",
    "checksum": "sha256:...",
    "started_at": "2024-01-01T12:00:00Z",
    "completed_at": null
  }
}
```

#### Get Update Status
```bash
GET /api/devices/:device_id/update/status
```

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message here"
}
```

Status codes:
- `200` - Success
- `401` - Unauthorized (missing/invalid API key)
- `404` - Not found
- `422` - Unprocessable entity

