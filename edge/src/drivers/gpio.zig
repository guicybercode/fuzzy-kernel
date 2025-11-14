const std = @import("std");

pub const GPIOError = error{
    ExportFailed,
    UnexportFailed,
    DirectionFailed,
    ValueFailed,
    DeviceNotFound,
};

pub const GPIODirection = enum {
    Input,
    Output,
};

pub const GPIOPin = struct {
    pin: u8,
    direction: GPIODirection,
    value_path: []const u8,
    exported: bool,

    pub fn init(pin: u8, direction: GPIODirection) !GPIOPin {
        const pin_str = try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{pin});
        defer std.heap.page_allocator.free(pin_str);

        const export_path = "/sys/class/gpio/export";
        const export_fd = try std.posix.open(export_path, std.posix.O.WRONLY, 0);
        defer std.posix.close(export_fd);
        _ = try std.posix.write(export_fd, pin_str);

        std.time.sleep(100 * std.time.ns_per_ms);

        const direction_path = try std.fmt.allocPrint(std.heap.page_allocator, "/sys/class/gpio/gpio{d}/direction", .{pin});
        defer std.heap.page_allocator.free(direction_path);

        const direction_fd = try std.posix.open(direction_path, std.posix.O.WRONLY, 0);
        defer std.posix.close(direction_fd);

        const dir_str = if (direction == .Input) "in" else "out";
        _ = try std.posix.write(direction_fd, dir_str);

        const value_path = try std.fmt.allocPrint(std.heap.page_allocator, "/sys/class/gpio/gpio{d}/value", .{pin});

        return GPIOPin{
            .pin = pin,
            .direction = direction,
            .value_path = value_path,
            .exported = true,
        };
    }

    pub fn deinit(self: *GPIOPin) void {
        if (self.exported) {
            const pin_str = try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{self.pin});
            defer std.heap.page_allocator.free(pin_str);

            const unexport_path = "/sys/class/gpio/unexport";
            const unexport_fd = std.posix.open(unexport_path, std.posix.O.WRONLY, 0) catch return;
            defer std.posix.close(unexport_fd);
            _ = std.posix.write(unexport_fd, pin_str) catch {};

            std.heap.page_allocator.free(self.value_path);
            self.exported = false;
        }
    }

    pub fn read(self: *GPIOPin) !u8 {
        const fd = try std.posix.open(self.value_path, std.posix.O.RDONLY, 0);
        defer std.posix.close(fd);

        var buffer: [1]u8 = undefined;
        _ = try std.posix.read(fd, &buffer);
        
        return if (buffer[0] == '1') 1 else 0;
    }

    pub fn write(self: *GPIOPin, value: u8) !void {
        if (self.direction != .Output) {
            return error.DirectionFailed;
        }

        const fd = try std.posix.open(self.value_path, std.posix.O.WRONLY, 0);
        defer std.posix.close(fd);

        const value_str = if (value == 1) "1" else "0";
        _ = try std.posix.write(fd, value_str);
    }
};

