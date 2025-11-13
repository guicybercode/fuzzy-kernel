const std = @import("std");

pub const TlsContext = struct {
    allocator: std.mem.Allocator,
    ca_cert_path: ?[]const u8,
    client_cert_path: ?[]const u8,
    client_key_path: ?[]const u8,
    
    pub fn init(
        allocator: std.mem.Allocator,
        ca_cert: ?[]const u8,
        client_cert: ?[]const u8,
        client_key: ?[]const u8,
    ) !*TlsContext {
        const ctx = try allocator.create(TlsContext);
        ctx.* = TlsContext{
            .allocator = allocator,
            .ca_cert_path = ca_cert,
            .client_cert_path = client_cert,
            .client_key_path = client_key,
        };
        return ctx;
    }
    
    pub fn deinit(self: *TlsContext) void {
        self.allocator.destroy(self);
    }
    
    pub fn wrapSocket(self: *TlsContext, socket: std.net.Stream) !TlsSocket {
        _ = self;
        return TlsSocket{
            .inner = socket,
        };
    }
};

pub const TlsSocket = struct {
    inner: std.net.Stream,
    
    pub fn read(self: *TlsSocket, buffer: []u8) !usize {
        return try self.inner.read(buffer);
    }
    
    pub fn write(self: *TlsSocket, data: []const u8) !usize {
        return try self.inner.write(data);
    }
    
    pub fn close(self: *TlsSocket) void {
        self.inner.close();
    }
};

