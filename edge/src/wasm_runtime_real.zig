const std = @import("std");
const c = @cImport({
    @cInclude("wasmtime.h");
});

pub const WasmError = error{
    ModuleNotFound,
    FunctionNotFound,
    ExecutionFailed,
    InitFailed,
    LoadFailed,
    CompileFailed,
    InstantiateFailed,
};

pub const WasmModule = struct {
    allocator: std.mem.Allocator,
    module_path: []const u8,
    engine: ?*c.wasm_engine_t,
    store: ?*c.wasmtime_store_t,
    module: ?*c.wasm_module_t,
    instance: ?*c.wasm_instance_t,
    initialized: bool,

    pub fn init(allocator: std.mem.Allocator, module_path: []const u8) !*WasmModule {
        const module = try allocator.create(WasmModule);
        module.* = WasmModule{
            .allocator = allocator,
            .module_path = module_path,
            .engine = null,
            .store = null,
            .module = null,
            .instance = null,
            .initialized = false,
        };
        return module;
    }

    pub fn deinit(self: *WasmModule) void {
        if (self.initialized) {
            if (self.instance) |inst| {
                c.wasm_instance_delete(inst);
            }
            if (self.module) |mod| {
                c.wasm_module_delete(mod);
            }
            if (self.store) |store| {
                c.wasmtime_store_delete(store);
            }
            if (self.engine) |eng| {
                c.wasm_engine_delete(eng);
            }
            self.initialized = false;
        }
        self.allocator.destroy(self);
    }

    pub fn load(self: *WasmModule) !void {
        self.engine = c.wasm_engine_new();
        if (self.engine == null) return error.InitFailed;

        var config: c.wasmtime_config_t = undefined;
        c.wasmtime_config_wasm_threads_set(&config, false);
        c.wasmtime_config_wasm_reference_types_set(&config, true);
        c.wasmtime_config_wasm_simd_set(&config, false);

        const file = try std.fs.cwd().openFile(self.module_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const wasm_bytes = try self.allocator.alloc(u8, file_size);
        defer self.allocator.free(wasm_bytes);
        _ = try file.readAll(wasm_bytes);

        var wasm: c.wasm_byte_vec_t = undefined;
        wasm.size = wasm_bytes.len;
        wasm.data = wasm_bytes.ptr;

        var module: ?*c.wasm_module_t = null;
        var error: c.wasmtime_error_t = undefined;
        const ret = c.wasmtime_module_new(self.engine, &wasm, &module, &error);
        if (ret != 0) {
            c.wasmtime_error_delete(&error);
            return error.CompileFailed;
        }
        self.module = module;

        var store: ?*c.wasmtime_store_t = null;
        const ret2 = c.wasmtime_store_new(self.engine, null, &store);
        if (ret2 != 0) return error.InitFailed;
        self.store = store;

        var instance: ?*c.wasm_instance_t = null;
        var trap: ?*c.wasm_trap_t = null;
        const ret3 = c.wasmtime_instance_new(self.store, self.module, null, 0, &instance, &trap);
        if (ret3 != 0) {
            if (trap) |t| c.wasm_trap_delete(t);
            return error.InstantiateFailed;
        }
        self.instance = instance;
        self.initialized = true;
    }

    pub fn callFunction(self: *WasmModule, function_name: []const u8, args: []const i32) !i32 {
        if (!self.initialized) return error.ModuleNotFound;

        const exports = c.wasm_instance_exports(self.instance);
        var func: ?*c.wasm_func_t = null;

        var i: usize = 0;
        while (i < exports.size) : (i += 1) {
            const export_ = exports.data[i];
            const name = c.wasm_export_name(&export_);
            if (std.mem.eql(u8, std.mem.span(name), function_name)) {
                const val = c.wasm_export_value(&export_);
                if (c.wasm_externkind(val) == c.WASM_EXTERN_FUNC) {
                    func = c.wasm_extern_as_func(val);
                    break;
                }
            }
        }

        if (func == null) return error.FunctionNotFound;

        var wasm_args = try self.allocator.alloc(c.wasm_val_t, args.len);
        defer self.allocator.free(wasm_args);

        for (args, 0..) |arg, idx| {
            wasm_args[idx].kind = c.WASM_I32;
            wasm_args[idx].of.i32 = arg;
        }

        var results: [1]c.wasm_val_t = undefined;
        var trap: ?*c.wasm_trap_t = null;
        const ret = c.wasm_func_call(func, wasm_args.ptr, wasm_args.len, &results, 1, &trap);
        if (ret != 0) {
            if (trap) |t| c.wasm_trap_delete(t);
            return error.ExecutionFailed;
        }

        return results[0].of.i32;
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

