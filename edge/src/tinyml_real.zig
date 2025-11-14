const std = @import("std");
const c = @cImport({
    @cInclude("tensorflow/lite/c/common.h");
    @cInclude("tensorflow/lite/c/c_api.h");
});

pub const TinyMLError = error{
    ModelNotFound,
    LoadFailed,
    InferenceFailed,
    InitFailed,
    AllocateTensorsFailed,
    InvokeFailed,
    InvalidInputSize,
};

pub const TinyMLModel = struct {
    allocator: std.mem.Allocator,
    model_path: []const u8,
    model: ?*c.TfLiteModel,
    interpreter: ?*c.TfLiteInterpreter,
    interpreter_options: ?*c.TfLiteInterpreterOptions,
    input_tensor: ?*c.TfLiteTensor,
    output_tensor: ?*c.TfLiteTensor,
    initialized: bool,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !*TinyMLModel {
        const model = try allocator.create(TinyMLModel);
        model.* = TinyMLModel{
            .allocator = allocator,
            .model_path = model_path,
            .model = null,
            .interpreter = null,
            .interpreter_options = null,
            .input_tensor = null,
            .output_tensor = null,
            .initialized = false,
        };
        return model;
    }

    pub fn deinit(self: *TinyMLModel) void {
        if (self.initialized) {
            if (self.interpreter) |interp| {
                c.TfLiteInterpreterDelete(interp);
            }
            if (self.interpreter_options) |opts| {
                c.TfLiteInterpreterOptionsDelete(opts);
            }
            if (self.model) |mod| {
                c.TfLiteModelDelete(mod);
            }
            self.initialized = false;
        }
        self.allocator.destroy(self);
    }

    pub fn load(self: *TinyMLModel) !void {
        const file = try std.fs.cwd().openFile(self.model_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const model_data = try self.allocator.alloc(u8, file_size);
        defer self.allocator.free(model_data);
        _ = try file.readAll(model_data);

        self.model = c.TfLiteModelCreate(model_data.ptr, model_data.len);
        if (self.model == null) return error.LoadFailed;

        self.interpreter_options = c.TfLiteInterpreterOptionsCreate();
        if (self.interpreter_options == null) {
            c.TfLiteModelDelete(self.model);
            return error.InitFailed;
        }

        c.TfLiteInterpreterOptionsSetNumThreads(self.interpreter_options, 1);

        self.interpreter = c.TfLiteInterpreterCreate(self.model, self.interpreter_options);
        if (self.interpreter == null) {
            c.TfLiteInterpreterOptionsDelete(self.interpreter_options);
            c.TfLiteModelDelete(self.model);
            return error.InitFailed;
        }

        const ret = c.TfLiteInterpreterAllocateTensors(self.interpreter);
        if (ret != c.kTfLiteOk) {
            c.TfLiteInterpreterDelete(self.interpreter);
            c.TfLiteInterpreterOptionsDelete(self.interpreter_options);
            c.TfLiteModelDelete(self.model);
            return error.AllocateTensorsFailed;
        }

        self.input_tensor = c.TfLiteInterpreterGetInputTensor(self.interpreter, 0);
        self.output_tensor = c.TfLiteInterpreterGetOutputTensor(self.interpreter, 0);

        if (self.input_tensor == null or self.output_tensor == null) {
            c.TfLiteInterpreterDelete(self.interpreter);
            c.TfLiteInterpreterOptionsDelete(self.interpreter_options);
            c.TfLiteModelDelete(self.model);
            return error.InitFailed;
        }

        self.initialized = true;
    }

    pub fn predict(self: *TinyMLModel, input: []const f32) ![]f32 {
        if (!self.initialized) return error.ModelNotFound;
        if (self.input_tensor == null or self.output_tensor == null) return error.ModelNotFound;

        const input_size = c.TfLiteTensorByteSize(self.input_tensor);
        const expected_size = input.len * @sizeOf(f32);
        if (input_size != expected_size) return error.InvalidInputSize;

        const input_data = c.TfLiteTensorData(self.input_tensor);
        if (input_data == null) return error.InferenceFailed;

        @memcpy(@ptrCast([*]u8, input_data)[0..expected_size], std.mem.sliceAsBytes(input));

        const ret = c.TfLiteInterpreterInvoke(self.interpreter);
        if (ret != c.kTfLiteOk) return error.InvokeFailed;

        const output_size = c.TfLiteTensorByteSize(self.output_tensor);
        const output_count = output_size / @sizeOf(f32);
        const output_data = c.TfLiteTensorData(self.output_tensor);
        if (output_data == null) return error.InferenceFailed;

        const output = try self.allocator.alloc(f32, output_count);
        @memcpy(std.mem.sliceAsBytes(output), @ptrCast([*]u8, output_data)[0..output_size]);

        return output;
    }
};

