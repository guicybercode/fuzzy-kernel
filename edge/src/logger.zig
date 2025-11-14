const std = @import("std");

pub const LogLevel = enum {
    Debug,
    Info,
    Warning,
    Error,
};

pub const Logger = struct {
    allocator: std.mem.Allocator,
    level: LogLevel,
    output_file: ?std.fs.File,

    pub fn init(allocator: std.mem.Allocator, level: LogLevel, log_file: ?[]const u8) !Logger {
        var output_file: ?std.fs.File = null;
        
        if (log_file) |path| {
            const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
            output_file = file;
        }

        return Logger{
            .allocator = allocator,
            .level = level,
            .output_file = output_file,
        };
    }

    pub fn deinit(self: *Logger) void {
        if (self.output_file) |file| {
            file.close();
        }
    }

    pub fn log(self: *Logger, level: LogLevel, message: []const u8, metadata: ?std.json.Value) !void {
        if (@intFromEnum(level) < @intFromEnum(self.level)) {
            return;
        }

        const timestamp = std.time.timestamp();
        const level_str = switch (level) {
            .Debug => "DEBUG",
            .Info => "INFO",
            .Warning => "WARNING",
            .Error => "ERROR",
        };

        var json_obj = std.json.ObjectMap.init(self.allocator);
        defer json_obj.deinit();

        try json_obj.put("timestamp", std.json.Value{ .integer = timestamp });
        try json_obj.put("level", std.json.Value{ .string = level_str });
        try json_obj.put("message", std.json.Value{ .string = message });

        if (metadata) |meta| {
            try json_obj.put("metadata", meta);
        }

        const json_value = std.json.Value{ .object = json_obj };
        var json_string = std.ArrayList(u8).init(self.allocator);
        defer json_string.deinit();

        try std.json.stringify(json_value, .{}, json_string.writer());
        try json_string.append('\n');

        const output = json_string.items;

        if (self.output_file) |file| {
            _ = try file.write(output);
            try file.flush();
        } else {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{s}", .{output});
        }
    }

    pub fn debug(self: *Logger, message: []const u8, metadata: ?std.json.Value) !void {
        try self.log(.Debug, message, metadata);
    }

    pub fn info(self: *Logger, message: []const u8, metadata: ?std.json.Value) !void {
        try self.log(.Info, message, metadata);
    }

    pub fn warning(self: *Logger, message: []const u8, metadata: ?std.json.Value) !void {
        try self.log(.Warning, message, metadata);
    }

    pub fn error(self: *Logger, message: []const u8, metadata: ?std.json.Value) !void {
        try self.log(.Error, message, metadata);
    }
};

