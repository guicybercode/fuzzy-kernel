const std = @import("std");
const config = @import("../config/config.zig");
const mqtt = @import("mqtt_client.zig");
const sensors = @import("sensors.zig");
const cache = @import("cache.zig");
const wasm = @import("wasm_runtime.zig");
const tinyml = @import("tinyml.zig");

var should_exit = std.atomic.Value(bool).init(false);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Microkernel Edge Daemon Starting...\n", .{});

    const cfg = try config.Config.loadFromEnv(allocator);
    
    std.debug.print("Device ID: {s}\n", .{cfg.device_id});
    std.debug.print("MQTT Broker: {s}:{d}\n", .{ cfg.mqtt_broker_host, cfg.mqtt_broker_port });

    const mqtt_client = try mqtt.MqttClient.init(
        allocator,
        cfg.mqtt_broker_host,
        cfg.mqtt_broker_port,
        cfg.device_id,
        cfg.mqtt_use_tls,
    );
    defer mqtt_client.deinit();

    const data_cache = try cache.DataCache.init(allocator, cfg.cache_dir, 1000, true);
    defer data_cache.deinit();

    try data_cache.loadFromDisk();
    std.debug.print("Cache loaded from disk\n", .{});

    const sensor_manager = try sensors.SensorManager.init(allocator);
    defer sensor_manager.deinit();

    const temp_sensor = try sensors.TemperatureSensor.init(allocator, "/dev/temp0");
    try sensor_manager.addSensor(temp_sensor.interface());

    const humidity_sensor = try sensors.HumiditySensor.init(allocator, "/dev/humidity0");
    try sensor_manager.addSensor(humidity_sensor.interface());

    const motion_sensor = try sensors.MotionSensor.init(allocator, "/dev/motion0");
    try sensor_manager.addSensor(motion_sensor.interface());

    std.debug.print("Sensors initialized: {} sensors\n", .{sensor_manager.sensors.items.len});

    const wasm_runtime = try wasm.WasmRuntime.init(allocator);
    defer wasm_runtime.deinit();
    std.debug.print("WebAssembly runtime initialized\n", .{});

    const ml_engine = try tinyml.TinyMLEngine.init(allocator);
    defer ml_engine.deinit();

    try ml_engine.loadModel("anomaly_detector", "/var/lib/microkernel/models/anomaly.bin", .AnomalyDetection);
    std.debug.print("TinyML model loaded\n", .{});

    try mqtt_client.connect();
    std.debug.print("Connected to MQTT broker\n", .{});

    var telemetry_topic_buffer: [128]u8 = undefined;
    const telemetry_topic = try std.fmt.bufPrint(&telemetry_topic_buffer, "devices/{s}/telemetry", .{cfg.device_id});

    var command_topic_buffer: [128]u8 = undefined;
    const command_topic = try std.fmt.bufPrint(&command_topic_buffer, "devices/{s}/commands", .{cfg.device_id});

    try mqtt_client.subscribe(command_topic, .AtLeastOnce);
    std.debug.print("Subscribed to commands topic: {s}\n", .{command_topic});

    var loop_count: usize = 0;
    while (!should_exit.load(.acquire)) {
        const readings = sensor_manager.readAll() catch |err| {
            std.debug.print("Error reading sensors: {}\n", .{err});
            std.time.sleep(cfg.sensor_poll_interval_ms * std.time.ns_per_ms);
            continue;
        };
        defer allocator.free(readings);

        for (readings) |reading| {
            const sensor_name = @tagName(reading.sensor_type);
            std.debug.print("[{d}] {s}: {d:.2} {s}\n", .{ 
                reading.timestamp, 
                sensor_name, 
                reading.value, 
                reading.unit 
            });

            const anomaly_result = ml_engine.predictAnomaly("anomaly_detector", reading.value) catch |err| {
                std.debug.print("Error in anomaly detection: {}\n", .{err});
                continue;
            };

            if (anomaly_result.anomaly_detected) {
                std.debug.print("⚠️  ANOMALY DETECTED! Confidence: {d:.2}%\n", .{anomaly_result.confidence * 100.0});
            }

            var payload_buffer: [512]u8 = undefined;
            const payload = std.fmt.bufPrint(&payload_buffer, 
                "{{\"device_id\":\"{s}\",\"sensor\":\"{s}\",\"value\":{d:.2},\"unit\":\"{s}\",\"timestamp\":{d},\"anomaly\":{},\"confidence\":{d:.2}}}",
                .{
                    cfg.device_id,
                    sensor_name,
                    reading.value,
                    reading.unit,
                    reading.timestamp,
                    anomaly_result.anomaly_detected,
                    anomaly_result.confidence,
                }
            ) catch continue;

            mqtt_client.publish(telemetry_topic, payload, .AtLeastOnce) catch |err| {
                std.debug.print("Failed to publish telemetry: {}\n", .{err});
                
                var cache_key_buffer: [64]u8 = undefined;
                const cache_key = std.fmt.bufPrint(&cache_key_buffer, "telemetry_{d}", .{loop_count}) catch continue;
                data_cache.put(cache_key, payload, 3600) catch |cache_err| {
                    std.debug.print("Failed to cache telemetry: {}\n", .{cache_err});
                };
            };
        }

        mqtt_client.processMessages() catch |err| {
            std.debug.print("Error processing MQTT messages: {}\n", .{err});
            mqtt_client.reconnect() catch |reconnect_err| {
                std.debug.print("Failed to reconnect: {}\n", .{reconnect_err});
            };
        };

        mqtt_client.flushQueue() catch |err| {
            std.debug.print("Error flushing message queue: {}\n", .{err});
        };

        data_cache.cleanExpired();

        if (loop_count % 10 == 0) {
            data_cache.syncToDisk() catch |err| {
                std.debug.print("Failed to sync cache to disk: {}\n", .{err});
            };
        }

        loop_count += 1;
        std.time.sleep(cfg.sensor_poll_interval_ms * std.time.ns_per_ms);

        if (loop_count >= 20) {
            std.debug.print("Demo complete after 20 iterations\n", .{});
            break;
        }
    }

    std.debug.print("Shutting down gracefully...\n", .{});
    mqtt_client.disconnect();
    try data_cache.syncToDisk();
}

