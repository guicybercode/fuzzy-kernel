const std = @import("std");

pub const CoapMethod = enum(u8) {
    Get = 1,
    Post = 2,
    Put = 3,
    Delete = 4,
};

pub const CoapMessageType = enum(u8) {
    Confirmable = 0,
    NonConfirmable = 1,
    Acknowledgement = 2,
    Reset = 3,
};

pub const CoapMessage = struct {
    message_type: CoapMessageType,
    method: CoapMethod,
    message_id: u16,
    token: []const u8,
    uri_path: []const u8,
    payload: []const u8,
};

pub const CoapClient = struct {
    allocator: std.mem.Allocator,
    server_host: []const u8,
    server_port: u16,
    use_dtls: bool,
    socket: ?std.net.Stream,
    message_id: u16,
    
    pub fn init(
        allocator: std.mem.Allocator,
        server_host: []const u8,
        server_port: u16,
        use_dtls: bool,
    ) !*CoapClient {
        const client = try allocator.create(CoapClient);
        client.* = CoapClient{
            .allocator = allocator,
            .server_host = server_host,
            .server_port = server_port,
            .use_dtls = use_dtls,
            .socket = null,
            .message_id = 1,
        };
        return client;
    }
    
    pub fn deinit(self: *CoapClient) void {
        self.disconnect();
        self.allocator.destroy(self);
    }
    
    pub fn connect(self: *CoapClient) !void {
        const address = try std.net.Address.parseIp(self.server_host, self.server_port);
        const stream = try std.net.tcpConnectToAddress(address);
        self.socket = stream;
    }
    
    pub fn disconnect(self: *CoapClient) void {
        if (self.socket) |socket| {
            socket.close();
            self.socket = null;
        }
    }
    
    pub fn get(self: *CoapClient, uri_path: []const u8) ![]const u8 {
        const msg = CoapMessage{
            .message_type = .Confirmable,
            .method = .Get,
            .message_id = self.getNextMessageId(),
            .token = &[_]u8{},
            .uri_path = uri_path,
            .payload = &[_]u8{},
        };
        
        return try self.sendRequest(msg);
    }
    
    pub fn post(self: *CoapClient, uri_path: []const u8, payload: []const u8) ![]const u8 {
        const msg = CoapMessage{
            .message_type = .Confirmable,
            .method = .Post,
            .message_id = self.getNextMessageId(),
            .token = &[_]u8{},
            .uri_path = uri_path,
            .payload = payload,
        };
        
        return try self.sendRequest(msg);
    }
    
    pub fn observe(self: *CoapClient, uri_path: []const u8) !void {
        _ = self;
        _ = uri_path;
    }
    
    fn sendRequest(self: *CoapClient, msg: CoapMessage) ![]const u8 {
        if (self.socket == null) return error.NotConnected;
        
        var buffer: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        const writer = fbs.writer();
        
        const version: u8 = 1;
        const type_code: u8 = @intFromEnum(msg.message_type);
        const token_len: u8 = @intCast(msg.token.len);
        const header_byte: u8 = (version << 6) | (type_code << 4) | token_len;
        try writer.writeByte(header_byte);
        
        try writer.writeByte(@intFromEnum(msg.method));
        
        try writer.writeInt(u16, msg.message_id, .big);
        
        if (msg.token.len > 0) {
            try writer.writeAll(msg.token);
        }
        
        _ = try self.socket.?.write(fbs.getWritten());
        
        var response_buffer: [1024]u8 = undefined;
        const bytes_read = try self.socket.?.read(&response_buffer);
        
        return try self.allocator.dupe(u8, response_buffer[0..bytes_read]);
    }
    
    fn getNextMessageId(self: *CoapClient) u16 {
        const id = self.message_id;
        self.message_id +%= 1;
        return id;
    }
};

