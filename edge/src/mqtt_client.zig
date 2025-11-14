const std = @import("std");

pub const QoS = enum(u8) {
    AtMostOnce = 0,
    AtLeastOnce = 1,
    ExactlyOnce = 2,
};

pub const MqttMessage = struct {
    topic: []const u8,
    payload: []const u8,
    qos: QoS,
};

pub const ConnectionState = enum {
    Disconnected,
    Connecting,
    Connected,
    Reconnecting,
};

pub const MqttClient = struct {
    allocator: std.mem.Allocator,
    broker_host: []const u8,
    broker_port: u16,
    client_id: []const u8,
    use_tls: bool,
    state: ConnectionState,
    socket: ?std.net.Stream,
    reconnect_delay_ms: u64,
    max_reconnect_delay_ms: u64,
    current_reconnect_delay_ms: u64,
    subscribed_topics: std.ArrayList([]const u8),
    message_queue: std.ArrayList(MqttMessage),
    
    pub fn init(
        allocator: std.mem.Allocator,
        broker_host: []const u8,
        broker_port: u16,
        client_id: []const u8,
        use_tls: bool,
    ) !*MqttClient {
        const client = try allocator.create(MqttClient);
        client.* = MqttClient{
            .allocator = allocator,
            .broker_host = broker_host,
            .broker_port = broker_port,
            .client_id = client_id,
            .use_tls = use_tls,
            .state = .Disconnected,
            .socket = null,
            .reconnect_delay_ms = 1000,
            .max_reconnect_delay_ms = 60000,
            .current_reconnect_delay_ms = 1000,
            .subscribed_topics = std.ArrayList([]const u8).init(allocator),
            .message_queue = std.ArrayList(MqttMessage).init(allocator),
        };
        return client;
    }
    
    pub fn deinit(self: *MqttClient) void {
        self.disconnect();
        self.subscribed_topics.deinit();
        self.message_queue.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn connect(self: *MqttClient) !void {
        self.state = .Connecting;
        
        const address = try std.net.Address.parseIp(self.broker_host, self.broker_port);
        const stream = try std.net.tcpConnectToAddress(address);
        
        if (self.use_tls) {
            return error.TlsNotImplemented;
        }
        
        self.socket = stream;
        
        try self.sendConnectPacket();
        
        var connack_buffer: [4]u8 = undefined;
        const connack_read = try self.socket.?.read(&connack_buffer);
        if (connack_read < 4) {
            return error.InvalidConnack;
        }
        
        if (connack_buffer[0] != 0x20) {
            return error.InvalidConnack;
        }
        
        if (connack_buffer[1] != 2) {
            return error.InvalidConnack;
        }
        
        const return_code = connack_buffer[3];
        if (return_code != 0) {
            return error.ConnectionRefused;
        }
        
        self.state = .Connected;
        self.current_reconnect_delay_ms = self.reconnect_delay_ms;
        
        try self.resubscribeAll();
    }
    
    pub fn disconnect(self: *MqttClient) void {
        if (self.socket) |socket| {
            socket.close();
            self.socket = null;
        }
        self.state = .Disconnected;
    }
    
    pub fn reconnect(self: *MqttClient) !void {
        self.state = .Reconnecting;
        self.disconnect();
        
        std.time.sleep(self.current_reconnect_delay_ms * std.time.ns_per_ms);
        
        self.current_reconnect_delay_ms = @min(
            self.current_reconnect_delay_ms * 2,
            self.max_reconnect_delay_ms
        );
        
        try self.connect();
    }
    
    pub fn publish(
        self: *MqttClient,
        topic: []const u8,
        payload: []const u8,
        qos: QoS,
    ) !void {
        if (self.state != .Connected) {
            const msg = MqttMessage{
                .topic = try self.allocator.dupe(u8, topic),
                .payload = try self.allocator.dupe(u8, payload),
                .qos = qos,
            };
            try self.message_queue.append(msg);
            return;
        }
        
        try self.sendPublishPacket(topic, payload, qos);
    }
    
    pub fn subscribe(self: *MqttClient, topic: []const u8, qos: QoS) !void {
        const topic_copy = try self.allocator.dupe(u8, topic);
        try self.subscribed_topics.append(topic_copy);
        
        if (self.state == .Connected) {
            try self.sendSubscribePacket(topic, qos);
        }
    }
    
    fn resubscribeAll(self: *MqttClient) !void {
        for (self.subscribed_topics.items) |topic| {
            try self.sendSubscribePacket(topic, .AtLeastOnce);
        }
    }
    
    fn sendConnectPacket(self: *MqttClient) !void {
        if (self.socket == null) return error.NotConnected;
        
        var buffer: [256]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        const writer = fbs.writer();
        
        try writer.writeByte(0x10);
        
        const client_id_len: u16 = @intCast(self.client_id.len);
        const remaining_length: u32 = 10 + 2 + client_id_len;
        try self.writeRemainingLength(writer, remaining_length);
        
        try writer.writeInt(u16, 4, .big);
        try writer.writeAll("MQTT");
        
        try writer.writeByte(4);
        
        try writer.writeByte(0x02);
        
        try writer.writeInt(u16, 60, .big);
        
        try writer.writeInt(u16, client_id_len, .big);
        try writer.writeAll(self.client_id);
        
        _ = try self.socket.?.write(fbs.getWritten());
    }
    
    fn sendPublishPacket(self: *MqttClient, topic: []const u8, payload: []const u8, qos: QoS) !void {
        if (self.socket == null) return error.NotConnected;
        
        var buffer: [2048]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        const writer = fbs.writer();
        
        const qos_bits: u8 = @intFromEnum(qos);
        try writer.writeByte(0x30 | (qos_bits << 1));
        
        const topic_len: u16 = @intCast(topic.len);
        const payload_len: u32 = @intCast(payload.len);
        const remaining_length: u32 = 2 + topic_len + payload_len;
        
        try self.writeRemainingLength(writer, remaining_length);
        
        try writer.writeInt(u16, topic_len, .big);
        try writer.writeAll(topic);
        try writer.writeAll(payload);
        
        _ = try self.socket.?.write(fbs.getWritten());
    }
    
    fn sendSubscribePacket(self: *MqttClient, topic: []const u8, qos: QoS) !void {
        if (self.socket == null) return error.NotConnected;
        
        var buffer: [512]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        const writer = fbs.writer();
        
        try writer.writeByte(0x82);
        
        const topic_len: u16 = @intCast(topic.len);
        const remaining_length: u32 = 2 + 2 + topic_len + 1;
        try self.writeRemainingLength(writer, remaining_length);
        
        try writer.writeInt(u16, 1, .big);
        
        try writer.writeInt(u16, topic_len, .big);
        try writer.writeAll(topic);
        try writer.writeByte(@intFromEnum(qos));
        
        _ = try self.socket.?.write(fbs.getWritten());
    }
    
    fn writeRemainingLength(self: *MqttClient, writer: anytype, length: u32) !void {
        _ = self;
        var len = length;
        var encoded: [4]u8 = undefined;
        var count: usize = 0;
        
        while (len > 0) {
            var byte: u8 = @intCast(len % 128);
            len = len / 128;
            if (len > 0) {
                byte |= 0x80;
            }
            encoded[count] = byte;
            count += 1;
            if (count >= 4) break;
        }
        
        for (encoded[0..count]) |b| {
            try writer.writeByte(b);
        }
    }
    
    pub fn processMessages(self: *MqttClient) !void {
        if (self.state != .Connected or self.socket == null) return;
        
        var buffer: [4096]u8 = undefined;
        const bytes_read = self.socket.?.read(&buffer) catch |err| {
            if (err == error.WouldBlock) return;
            try self.reconnect();
            return;
        };
        
        if (bytes_read == 0) {
            try self.reconnect();
            return;
        }
        
        if (bytes_read < 2) return;
        
        const message_type = (buffer[0] >> 4) & 0x0F;
        
        if (message_type == 3) {
            const remaining_length = try self.readRemainingLength(buffer[1..]);
            if (bytes_read < remaining_length + 2) return;
            
            var pos: usize = 2;
            const topic_len = std.mem.readInt(u16, buffer[pos..pos+2], .big);
            pos += 2;
            
            if (bytes_read < pos + topic_len) return;
            const topic = buffer[pos..pos+topic_len];
            pos += topic_len;
            
            if (bytes_read < pos + 2) return;
            const packet_id = std.mem.readInt(u16, buffer[pos..pos+2], .big);
            pos += 2;
            
            if (bytes_read < pos) return;
            const payload = buffer[pos..bytes_read];
            _ = packet_id;
            _ = topic;
            _ = payload;
        }
    }
    
    fn readRemainingLength(self: *MqttClient, buffer: []const u8) !u32 {
        _ = self;
        var multiplier: u32 = 1;
        var value: u32 = 0;
        var pos: usize = 0;
        
        while (pos < buffer.len and pos < 4) {
            const byte = buffer[pos];
            value += (byte & 0x7F) * multiplier;
            multiplier *= 128;
            pos += 1;
            if ((byte & 0x80) == 0) break;
        }
        
        return value;
    }
    
    pub fn flushQueue(self: *MqttClient) !void {
        if (self.state != .Connected) return;
        
        for (self.message_queue.items) |msg| {
            try self.sendPublishPacket(msg.topic, msg.payload, msg.qos);
            self.allocator.free(msg.topic);
            self.allocator.free(msg.payload);
        }
        
        self.message_queue.clearRetainingCapacity();
    }
};

