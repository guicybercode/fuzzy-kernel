const std = @import("std");

pub const SPIError = error{
    DeviceNotFound,
    ReadFailed,
    WriteFailed,
    Timeout,
};

pub const SPIMode = enum(u8) {
    Mode0 = 0,
    Mode1 = 1,
    Mode2 = 2,
    Mode3 = 3,
};

pub const SPIDevice = struct {
    bus: u8,
    cs: u8,
    mode: SPIMode,
    max_speed: u32,
    fd: ?std.posix.fd_t,

    pub fn init(bus: u8, cs: u8, mode: SPIMode, max_speed: u32) !SPIDevice {
        const device_path = try std.fmt.allocPrint(std.heap.page_allocator, "/dev/spidev{d}.{d}", .{ bus, cs });
        defer std.heap.page_allocator.free(device_path);

        const fd = try std.posix.open(device_path, std.posix.O.RDWR, 0);

        const spi_ioc_wr_mode: c_ulong = 0x40016b01;
        const spi_ioc_wr_max_speed_hz: c_ulong = 0x40046b04;
        var mode_val: u8 = @intFromEnum(mode);
        var speed: u32 = max_speed;

        _ = std.posix.ioctl(fd, spi_ioc_wr_mode, &mode_val);
        _ = std.posix.ioctl(fd, spi_ioc_wr_max_speed_hz, &speed);

        return SPIDevice{
            .bus = bus,
            .cs = cs,
            .mode = mode,
            .max_speed = max_speed,
            .fd = fd,
        };
    }

    pub fn deinit(self: *SPIDevice) void {
        if (self.fd) |fd| {
            std.posix.close(fd);
            self.fd = null;
        }
    }

    pub fn transfer(self: *SPIDevice, tx_buf: []const u8, rx_buf: []u8) !usize {
        const fd = self.fd orelse return error.DeviceNotFound;
        
        if (tx_buf.len != rx_buf.len) {
            return error.InvalidLength;
        }

        const bytes_written = try std.posix.write(fd, tx_buf);
        _ = try std.posix.read(fd, rx_buf);
        
        return bytes_written;
    }
};

