const std = @import("std");
const mqtt = @import("mqtt_client.zig");

pub const CommandType = enum {
    Update,
    Restart,
    Configure,
    Unknown,
};

pub const Command = struct {
    command_type: CommandType,
    payload: []const u8,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *Command) void {
        self.allocator.free(self.payload);
    }
    
    pub fn parse(allocator: std.mem.Allocator, json_str: []const u8) !Command {
        _ = allocator;
        _ = json_str;
        
        var cmd = Command{
            .command_type = .Unknown,
            .payload = try allocator.dupe(u8, json_str),
            .allocator = allocator,
        };
        
        if (std.mem.indexOf(u8, json_str, "\"command\":\"update\"") != null) {
            cmd.command_type = .Update;
        } else if (std.mem.indexOf(u8, json_str, "\"command\":\"restart\"") != null) {
            cmd.command_type = .Restart;
        } else if (std.mem.indexOf(u8, json_str, "\"command\":\"configure\"") != null) {
            cmd.command_type = .Configure;
        }
        
        return cmd;
    }
};

pub const CommandHandler = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !*CommandHandler {
        const handler = try allocator.create(CommandHandler);
        handler.* = CommandHandler{
            .allocator = allocator,
        };
        return handler;
    }
    
    pub fn setCallbacks(
        on_update: ?*const fn (version: []const u8) void,
        on_restart: ?*const fn () void,
        on_configure: ?*const fn (config: []const u8) void,
    ) void {
        global_on_update = on_update;
        global_on_restart = on_restart;
        global_on_configure = on_configure;
    }
    
    pub fn deinit(self: *CommandHandler) void {
        self.allocator.destroy(self);
    }
    
    pub fn handleCommand(self: *CommandHandler, topic: []const u8, payload: []const u8) !void {
        _ = topic;
        
        const cmd = try Command.parse(self.allocator, payload);
        defer cmd.deinit();
        
        switch (cmd.command_type) {
            .Update => {
                std.debug.print("Received UPDATE command\n", .{});
                if (global_on_update) |callback| {
                    const version_start = std.mem.indexOf(u8, payload, "\"version\":\"") orelse {
                        std.debug.print("Could not parse version from payload\n", .{});
                        return;
                    };
                    const version_end = std.mem.indexOfPos(u8, payload, version_start + 11, "\"") orelse {
                        std.debug.print("Could not find version end\n", .{});
                        return;
                    };
                    const version = payload[version_start + 11 .. version_end];
                    callback(version);
                }
            },
            .Restart => {
                std.debug.print("Received RESTART command\n", .{});
                if (global_on_restart) |callback| {
                    callback();
                }
            },
            .Configure => {
                std.debug.print("Received CONFIGURE command\n", .{});
                if (global_on_configure) |callback| {
                    callback(payload);
                }
            },
            .Unknown => {
                std.debug.print("Received UNKNOWN command: {s}\n", .{payload});
            },
        }
    }
};

