const std = @import("std");

pub const Config = struct {
    device_id: []const u8,
    mqtt_broker_host: []const u8,
    mqtt_broker_port: u16,
    mqtt_use_tls: bool,
    mqtt_ca_cert_path: ?[]const u8,
    mqtt_client_cert_path: ?[]const u8,
    mqtt_client_key_path: ?[]const u8,
    reconnect_interval_ms: u64,
    max_reconnect_interval_ms: u64,
    cache_dir: []const u8,
    sensor_poll_interval_ms: u64,
    
    pub fn loadFromEnv(allocator: std.mem.Allocator) !Config {
        const device_id = std.process.getEnvVarOwned(allocator, "DEVICE_ID") catch "device-001";
        const mqtt_host = std.process.getEnvVarOwned(allocator, "MQTT_BROKER_HOST") catch "localhost";
        const mqtt_port = std.process.getEnvVarOwned(allocator, "MQTT_BROKER_PORT") catch "1883";
        const port = try std.fmt.parseInt(u16, mqtt_port, 10);
        
        return Config{
            .device_id = device_id,
            .mqtt_broker_host = mqtt_host,
            .mqtt_broker_port = port,
            .mqtt_use_tls = true,
            .mqtt_ca_cert_path = std.process.getEnvVarOwned(allocator, "MQTT_CA_CERT") catch null,
            .mqtt_client_cert_path = std.process.getEnvVarOwned(allocator, "MQTT_CLIENT_CERT") catch null,
            .mqtt_client_key_path = std.process.getEnvVarOwned(allocator, "MQTT_CLIENT_KEY") catch null,
            .reconnect_interval_ms = 1000,
            .max_reconnect_interval_ms = 60000,
            .cache_dir = "/var/lib/microkernel",
            .sensor_poll_interval_ms = 5000,
        };
    }
};

