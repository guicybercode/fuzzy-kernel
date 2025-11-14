const std = @import("std");

pub const WasmError = error{
    ModuleNotFound,
    FunctionNotFound,
    ExecutionFailed,
    NotImplemented,
};

pub const WasmModule = struct {
    allocator: std.mem.Allocator,
    module_path: []const u8,
    engine: ?*anyopaque,
    store: ?*anyopaque,
    module: ?*anyopaque,

    pub fn init(allocator: std.mem.Allocator, module_path: []const u8) !*WasmModule {
        const module = try allocator.create(WasmModule);
        module.* = WasmModule{
            .allocator = allocator,
            .module_path = module_path,
            .engine = null,
            .store = null,
            .module = null,
        };
        return module;
    }

    pub fn deinit(self: *WasmModule) void {
        self.allocator.destroy(self);
    }

    pub fn load(self: *WasmModule) !void {
        _ = self;
        return error.NotImplemented;
    }

    pub fn callFunction(self: *WasmModule, function_name: []const u8, args: []const i32) !i32 {
        _ = self;
        _ = function_name;
        _ = args;
        return error.NotImplemented;
    }
};

pub const WasmRuntime = struct {
    allocator: std.mem.Allocator,
    modules: std.StringHashMap(*WasmModule),

    pub fn init(allocator: std.mem.Allocator) !*WasmRuntime {
        const runtime = try allocator.create(WasmRuntime);
        runtime.* = WasmRuntime{
            .allocator = allocator,
            .modules = std.StringHashMap(*WasmModule).init(allocator),
        };
        return runtime;
    }

    pub fn deinit(self: *WasmRuntime) void {
        var iter = self.modules.valueIterator();
        while (iter.next()) |module| {
            module.*.deinit();
        }
        self.modules.deinit();
        self.allocator.destroy(self);
    }

    pub fn loadModule(self: *WasmRuntime, name: []const u8, path: []const u8) !void {
        const module = try WasmModule.init(self.allocator, path);
        try module.load();
        try self.modules.put(name, module);
    }

    pub fn executeScript(self: *WasmRuntime, module_name: []const u8, function_name: []const u8, args: []const i32) !i32 {
        const module = self.modules.get(module_name) orelse return error.ModuleNotFound;
        return try module.callFunction(function_name, args);
    }
};

