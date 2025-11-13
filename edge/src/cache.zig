const std = @import("std");

pub const CacheEntry = struct {
    key: []const u8,
    value: []const u8,
    timestamp: i64,
    ttl_seconds: ?i64,
};

pub const DataCache = struct {
    allocator: std.mem.Allocator,
    cache_dir: []const u8,
    entries: std.StringHashMap(CacheEntry),
    max_entries: usize,
    persist_enabled: bool,
    
    pub fn init(
        allocator: std.mem.Allocator,
        cache_dir: []const u8,
        max_entries: usize,
        persist: bool,
    ) !*DataCache {
        const cache = try allocator.create(DataCache);
        cache.* = DataCache{
            .allocator = allocator,
            .cache_dir = cache_dir,
            .entries = std.StringHashMap(CacheEntry).init(allocator),
            .max_entries = max_entries,
            .persist_enabled = persist,
        };
        
        if (persist) {
            std.fs.cwd().makeDir(cache_dir) catch |err| {
                if (err != error.PathAlreadyExists) {
                    return err;
                }
            };
        }
        
        return cache;
    }
    
    pub fn deinit(self: *DataCache) void {
        var iter = self.entries.valueIterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key);
            self.allocator.free(entry.value);
        }
        self.entries.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn put(self: *DataCache, key: []const u8, value: []const u8, ttl_seconds: ?i64) !void {
        if (self.entries.count() >= self.max_entries) {
            try self.evictOldest();
        }
        
        const key_copy = try self.allocator.dupe(u8, key);
        const value_copy = try self.allocator.dupe(u8, value);
        const timestamp = std.time.timestamp();
        
        const entry = CacheEntry{
            .key = key_copy,
            .value = value_copy,
            .timestamp = timestamp,
            .ttl_seconds = ttl_seconds,
        };
        
        try self.entries.put(key_copy, entry);
        
        if (self.persist_enabled) {
            try self.persistEntry(entry);
        }
    }
    
    pub fn get(self: *DataCache, key: []const u8) ?[]const u8 {
        const entry = self.entries.get(key) orelse return null;
        
        if (entry.ttl_seconds) |ttl| {
            const now = std.time.timestamp();
            if (now - entry.timestamp > ttl) {
                return null;
            }
        }
        
        return entry.value;
    }
    
    pub fn remove(self: *DataCache, key: []const u8) void {
        if (self.entries.fetchRemove(key)) |kv| {
            self.allocator.free(kv.value.key);
            self.allocator.free(kv.value.value);
            
            if (self.persist_enabled) {
                self.deletePersistedEntry(key) catch {};
            }
        }
    }
    
    pub fn clear(self: *DataCache) void {
        var iter = self.entries.valueIterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key);
            self.allocator.free(entry.value);
        }
        self.entries.clearRetainingCapacity();
        
        if (self.persist_enabled) {
            self.clearPersistedEntries() catch {};
        }
    }
    
    pub fn loadFromDisk(self: *DataCache) !void {
        if (!self.persist_enabled) return;
        
        var dir = std.fs.cwd().openDir(self.cache_dir, .{ .iterate = true }) catch return;
        defer dir.close();
        
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind != .file) continue;
            
            const file = try dir.openFile(entry.name, .{});
            defer file.close();
            
            const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
            defer self.allocator.free(content);
            
            const key = try self.allocator.dupe(u8, entry.name);
            const value = try self.allocator.dupe(u8, content);
            const timestamp = std.time.timestamp();
            
            const cache_entry = CacheEntry{
                .key = key,
                .value = value,
                .timestamp = timestamp,
                .ttl_seconds = null,
            };
            
            try self.entries.put(key, cache_entry);
        }
    }
    
    pub fn syncToDisk(self: *DataCache) !void {
        if (!self.persist_enabled) return;
        
        var iter = self.entries.valueIterator();
        while (iter.next()) |entry| {
            try self.persistEntry(entry.*);
        }
    }
    
    fn persistEntry(self: *DataCache, entry: CacheEntry) !void {
        var path_buffer: [256]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buffer, "{s}/{s}", .{ self.cache_dir, entry.key });
        
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        
        try file.writeAll(entry.value);
    }
    
    fn deletePersistedEntry(self: *DataCache, key: []const u8) !void {
        var path_buffer: [256]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buffer, "{s}/{s}", .{ self.cache_dir, key });
        
        try std.fs.cwd().deleteFile(path);
    }
    
    fn clearPersistedEntries(self: *DataCache) !void {
        var dir = try std.fs.cwd().openDir(self.cache_dir, .{ .iterate = true });
        defer dir.close();
        
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .file) {
                try dir.deleteFile(entry.name);
            }
        }
    }
    
    fn evictOldest(self: *DataCache) !void {
        var oldest_key: ?[]const u8 = null;
        var oldest_timestamp: i64 = std.math.maxInt(i64);
        
        var iter = self.entries.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.timestamp < oldest_timestamp) {
                oldest_timestamp = entry.value_ptr.timestamp;
                oldest_key = entry.key_ptr.*;
            }
        }
        
        if (oldest_key) |key| {
            self.remove(key);
        }
    }
    
    pub fn cleanExpired(self: *DataCache) void {
        const now = std.time.timestamp();
        
        var keys_to_remove = std.ArrayList([]const u8).init(self.allocator);
        defer keys_to_remove.deinit();
        
        var iter = self.entries.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.ttl_seconds) |ttl| {
                if (now - entry.value_ptr.timestamp > ttl) {
                    keys_to_remove.append(entry.key_ptr.*) catch continue;
                }
            }
        }
        
        for (keys_to_remove.items) |key| {
            self.remove(key);
        }
    }
};

