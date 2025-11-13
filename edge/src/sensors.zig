const std = @import("std");

pub const SensorType = enum {
    Temperature,
    Humidity,
    Motion,
    Pressure,
    Light,
    Custom,
};

pub const SensorReading = struct {
    sensor_type: SensorType,
    value: f64,
    unit: []const u8,
    timestamp: i64,
};

pub const SensorInterface = struct {
    vtable: *const VTable,
    ptr: *anyopaque,
    
    pub const VTable = struct {
        read: *const fn (ptr: *anyopaque) anyerror!SensorReading,
        calibrate: *const fn (ptr: *anyopaque) anyerror!void,
        deinit: *const fn (ptr: *anyopaque) void,
    };
    
    pub fn read(self: SensorInterface) !SensorReading {
        return self.vtable.read(self.ptr);
    }
    
    pub fn calibrate(self: SensorInterface) !void {
        return self.vtable.calibrate(self.ptr);
    }
    
    pub fn deinit(self: SensorInterface) void {
        self.vtable.deinit(self.ptr);
    }
};

pub const TemperatureSensor = struct {
    allocator: std.mem.Allocator,
    device_path: []const u8,
    offset: f64,
    
    pub fn init(allocator: std.mem.Allocator, device_path: []const u8) !*TemperatureSensor {
        const sensor = try allocator.create(TemperatureSensor);
        sensor.* = TemperatureSensor{
            .allocator = allocator,
            .device_path = device_path,
            .offset = 0.0,
        };
        return sensor;
    }
    
    pub fn interface(self: *TemperatureSensor) SensorInterface {
        return SensorInterface{
            .vtable = &.{
                .read = readImpl,
                .calibrate = calibrateImpl,
                .deinit = deinitImpl,
            },
            .ptr = self,
        };
    }
    
    fn readImpl(ptr: *anyopaque) !SensorReading {
        const self: *TemperatureSensor = @ptrCast(@alignCast(ptr));
        
        const random = std.crypto.random;
        const base_temp = 20.0;
        const variation = random.float(f64) * 10.0 - 5.0;
        const temperature = base_temp + variation + self.offset;
        
        const timestamp = std.time.timestamp();
        
        return SensorReading{
            .sensor_type = .Temperature,
            .value = temperature,
            .unit = "°C",
            .timestamp = timestamp,
        };
    }
    
    fn calibrateImpl(ptr: *anyopaque) !void {
        const self: *TemperatureSensor = @ptrCast(@alignCast(ptr));
        self.offset = 0.0;
    }
    
    fn deinitImpl(ptr: *anyopaque) void {
        const self: *TemperatureSensor = @ptrCast(@alignCast(ptr));
        self.allocator.destroy(self);
    }
};

pub const HumiditySensor = struct {
    allocator: std.mem.Allocator,
    device_path: []const u8,
    
    pub fn init(allocator: std.mem.Allocator, device_path: []const u8) !*HumiditySensor {
        const sensor = try allocator.create(HumiditySensor);
        sensor.* = HumiditySensor{
            .allocator = allocator,
            .device_path = device_path,
        };
        return sensor;
    }
    
    pub fn interface(self: *HumiditySensor) SensorInterface {
        return SensorInterface{
            .vtable = &.{
                .read = readImpl,
                .calibrate = calibrateImpl,
                .deinit = deinitImpl,
            },
            .ptr = self,
        };
    }
    
    fn readImpl(ptr: *anyopaque) !SensorReading {
        const self: *HumiditySensor = @ptrCast(@alignCast(ptr));
        _ = self;
        
        const random = std.crypto.random;
        const humidity = 50.0 + random.float(f64) * 30.0;
        
        const timestamp = std.time.timestamp();
        
        return SensorReading{
            .sensor_type = .Humidity,
            .value = humidity,
            .unit = "%",
            .timestamp = timestamp,
        };
    }
    
    fn calibrateImpl(ptr: *anyopaque) !void {
        _ = ptr;
    }
    
    fn deinitImpl(ptr: *anyopaque) void {
        const self: *HumiditySensor = @ptrCast(@alignCast(ptr));
        self.allocator.destroy(self);
    }
};

pub const MotionSensor = struct {
    allocator: std.mem.Allocator,
    device_path: []const u8,
    last_motion_time: i64,
    
    pub fn init(allocator: std.mem.Allocator, device_path: []const u8) !*MotionSensor {
        const sensor = try allocator.create(MotionSensor);
        sensor.* = MotionSensor{
            .allocator = allocator,
            .device_path = device_path,
            .last_motion_time = 0,
        };
        return sensor;
    }
    
    pub fn interface(self: *MotionSensor) SensorInterface {
        return SensorInterface{
            .vtable = &.{
                .read = readImpl,
                .calibrate = calibrateImpl,
                .deinit = deinitImpl,
            },
            .ptr = self,
        };
    }
    
    fn readImpl(ptr: *anyopaque) !SensorReading {
        const self: *MotionSensor = @ptrCast(@alignCast(ptr));
        
        const random = std.crypto.random;
        const motion_detected = random.float(f64) > 0.7;
        
        const timestamp = std.time.timestamp();
        
        if (motion_detected) {
            self.last_motion_time = timestamp;
        }
        
        return SensorReading{
            .sensor_type = .Motion,
            .value = if (motion_detected) 1.0 else 0.0,
            .unit = "bool",
            .timestamp = timestamp,
        };
    }
    
    fn calibrateImpl(ptr: *anyopaque) !void {
        _ = ptr;
    }
    
    fn deinitImpl(ptr: *anyopaque) void {
        const self: *MotionSensor = @ptrCast(@alignCast(ptr));
        self.allocator.destroy(self);
    }
};

pub const SensorManager = struct {
    allocator: std.mem.Allocator,
    sensors: std.ArrayList(SensorInterface),
    
    pub fn init(allocator: std.mem.Allocator) !*SensorManager {
        const manager = try allocator.create(SensorManager);
        manager.* = SensorManager{
            .allocator = allocator,
            .sensors = std.ArrayList(SensorInterface).init(allocator),
        };
        return manager;
    }
    
    pub fn deinit(self: *SensorManager) void {
        for (self.sensors.items) |sensor| {
            sensor.deinit();
        }
        self.sensors.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn addSensor(self: *SensorManager, sensor: SensorInterface) !void {
        try self.sensors.append(sensor);
    }
    
    pub fn readAll(self: *SensorManager) ![]SensorReading {
        var readings = try self.allocator.alloc(SensorReading, self.sensors.items.len);
        
        for (self.sensors.items, 0..) |sensor, i| {
            readings[i] = try sensor.read();
        }
        
        return readings;
    }
};

