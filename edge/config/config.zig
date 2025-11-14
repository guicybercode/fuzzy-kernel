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
        _ = allocator;
        const device_id_env = std.process.getEnvVar("DEVICE_ID") catch null;
        const device_id = if (device_id_env) |id| id else "device-001";
        
        const mqtt_host_env = std.process.getEnvVar("MQTT_BROKER_HOST") catch null;
        const mqtt_host = if (mqtt_host_env) |host| host else "localhost";
        
        const mqtt_port_env = std.process.getEnvVar("MQTT_BROKER_PORT") catch null;
        const mqtt_port_str = if (mqtt_port_env) |port| port else "1883";
        const port = try std.fmt.parseInt(u16, mqtt_port_str, 10);
        
        const use_tls_env = std.process.getEnvVar("MQTT_USE_TLS") catch null;
        const use_tls = if (use_tls_env) |val| std.mem.eql(u8, val, "true") else false;
        
        return Config{
            .device_id = device_id,
            .mqtt_broker_host = mqtt_host,
            .mqtt_broker_port = port,
            .mqtt_use_tls = use_tls,
            .mqtt_ca_cert_path = null,
            .mqtt_client_cert_path = null,
            .mqtt_client_key_path = null,
            .reconnect_interval_ms = 1000,
            .max_reconnect_interval_ms = 60000,
            .cache_dir = "/var/lib/microkernel",
            .sensor_poll_interval_ms = 5000,
        };
    }
};

