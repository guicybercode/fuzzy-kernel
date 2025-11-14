const std = @import("std");

pub const WatchdogError = error{
    InitFailed,
    FeedFailed,
    TimeoutFailed,
};

pub const Watchdog = struct {
    fd: ?std.posix.fd_t,
    timeout_seconds: u32,
    last_feed: i64,

    pub fn init(timeout_seconds: u32) !Watchdog {
        const watchdog_path = "/dev/watchdog";
        const fd = std.posix.open(watchdog_path, std.posix.O.WRONLY, 0) catch {
            return error.InitFailed;
        };

        const wdt_settimeout: c_ulong = 0x8004570c;
        var timeout: u32 = timeout_seconds;
        _ = std.posix.ioctl(fd, wdt_settimeout, &timeout);

        return Watchdog{
            .fd = fd,
            .timeout_seconds = timeout_seconds,
            .last_feed = std.time.timestamp(),
        };
    }

    pub fn deinit(self: *Watchdog) void {
        if (self.fd) |fd| {
            const magic_close: u8 = 'V';
            _ = std.posix.write(fd, &[_]u8{magic_close}) catch {};
            std.posix.close(fd);
            self.fd = null;
        }
    }

    pub fn feed(self: *Watchdog) !void {
        const fd = self.fd orelse return error.FeedFailed;
        
        const feed_char: u8 = 0x01;
        _ = try std.posix.write(fd, &[_]u8{feed_char});
        
        self.last_feed = std.time.timestamp();
    }

    pub fn shouldFeed(self: *Watchdog) bool {
        const now = std.time.timestamp();
        const elapsed = now - self.last_feed;
        return elapsed >= @as(i64, @intCast(self.timeout_seconds / 2));
    }
};

