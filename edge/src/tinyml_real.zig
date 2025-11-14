const std = @import("std");

pub const TinyMLError = error{
    ModelNotFound,
    LoadFailed,
    InferenceFailed,
    NotImplemented,
};

pub const TinyMLModel = struct {
    allocator: std.mem.Allocator,
    model_path: []const u8,
    interpreter: ?*anyopaque,
    input_tensor: ?*anyopaque,
    output_tensor: ?*anyopaque,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !*TinyMLModel {
        const model = try allocator.create(TinyMLModel);
        model.* = TinyMLModel{
            .allocator = allocator,
            .model_path = model_path,
            .interpreter = null,
            .input_tensor = null,
            .output_tensor = null,
        };
        return model;
    }

    pub fn deinit(self: *TinyMLModel) void {
        self.allocator.destroy(self);
    }

    pub fn load(self: *TinyMLModel) !void {
        _ = self;
        return error.NotImplemented;
    }

    pub fn predict(self: *TinyMLModel, input: []const f32) ![]f32 {
        _ = self;
        _ = input;
        return error.NotImplemented;
    }
};

