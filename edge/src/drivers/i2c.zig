const std = @import("std");

pub const I2CError = error{
    DeviceNotFound,
    ReadFailed,
    WriteFailed,
    Timeout,
};

pub const I2CDevice = struct {
    bus: u8,
    address: u8,
    fd: ?std.posix.fd_t,

    pub fn init(bus: u8, address: u8) !I2CDevice {
        const bus_path = try std.fmt.allocPrint(std.heap.page_allocator, "/dev/i2c-{d}", .{bus});
        defer std.heap.page_allocator.free(bus_path);

        const fd = try std.posix.open(bus_path, std.posix.O.RDWR, 0);
        
        const ioctl_i2c_slave: c_ulong = 0x0703;
        _ = std.posix.ioctl(fd, ioctl_i2c_slave, &address);

        return I2CDevice{
            .bus = bus,
            .address = address,
            .fd = fd,
        };
    }

    pub fn deinit(self: *I2CDevice) void {
        if (self.fd) |fd| {
            std.posix.close(fd);
            self.fd = null;
        }
    }

    pub fn read(self: *I2CDevice, buffer: []u8) !usize {
        const fd = self.fd orelse return error.DeviceNotFound;
        const bytes_read = try std.posix.read(fd, buffer);
        return bytes_read;
    }

    pub fn write(self: *I2CDevice, data: []const u8) !usize {
        const fd = self.fd orelse return error.DeviceNotFound;
        const bytes_written = try std.posix.write(fd, data);
        return bytes_written;
    }

    pub fn writeRead(self: *I2CDevice, write_buf: []const u8, read_buf: []u8) !usize {
        _ = try self.write(write_buf);
        std.time.sleep(10 * std.time.ns_per_ms);
        return try self.read(read_buf);
    }
};

