const std = @import("std");

pub const ModelType = enum {
    AnomalyDetection,
    Classification,
    Regression,
};

pub const InferenceResult = struct {
    prediction: f64,
    confidence: f64,
    anomaly_detected: bool,
    timestamp: i64,
};

pub const FeatureVector = struct {
    values: []f64,
    labels: [][]const u8,
};

pub const TinyMLModel = struct {
    allocator: std.mem.Allocator,
    model_path: []const u8,
    model_type: ModelType,
    input_size: usize,
    output_size: usize,
    weights: []f64,
    biases: []f64,
    threshold: f64,
    
    pub fn init(
        allocator: std.mem.Allocator,
        model_path: []const u8,
        model_type: ModelType,
    ) !*TinyMLModel {
        const model = try allocator.create(TinyMLModel);
        
        const input_size = 10;
        const output_size = 1;
        
        const weights = try allocator.alloc(f64, input_size * output_size);
        const biases = try allocator.alloc(f64, output_size);
        
        for (weights, 0..) |*w, i| {
            const random = std.crypto.random;
            w.* = (random.float(f64) - 0.5) * 0.1;
            _ = i;
        }
        
        for (biases) |*b| {
            b.* = 0.0;
        }
        
        model.* = TinyMLModel{
            .allocator = allocator,
            .model_path = model_path,
            .model_type = model_type,
            .input_size = input_size,
            .output_size = output_size,
            .weights = weights,
            .biases = biases,
            .threshold = 0.7,
        };
        
        return model;
    }
    
    pub fn deinit(self: *TinyMLModel) void {
        self.allocator.free(self.weights);
        self.allocator.free(self.biases);
        self.allocator.destroy(self);
    }
    
    pub fn load(self: *TinyMLModel) !void {
        _ = self;
    }
    
    pub fn predict(self: *TinyMLModel, features: []const f64) !InferenceResult {
        if (features.len != self.input_size) {
            return error.InvalidInputSize;
        }
        
        var output: f64 = 0.0;
        
        for (features, 0..) |feature, i| {
            output += feature * self.weights[i];
        }
        output += self.biases[0];
        
        const activation = 1.0 / (1.0 + @exp(-output));
        
        const anomaly_detected = activation > self.threshold;
        
        const timestamp = std.time.timestamp();
        
        return InferenceResult{
            .prediction = activation,
            .confidence = if (activation > 0.5) activation else 1.0 - activation,
            .anomaly_detected = anomaly_detected,
            .timestamp = timestamp,
        };
    }
    
    pub fn updateModel(self: *TinyMLModel, features: []const f64, label: f64) !void {
        if (features.len != self.input_size) {
            return error.InvalidInputSize;
        }
        
        const learning_rate = 0.01;
        
        const result = try self.predict(features);
        const error_val = label - result.prediction;
        
        for (features, 0..) |feature, i| {
            self.weights[i] += learning_rate * error_val * feature;
        }
        self.biases[0] += learning_rate * error_val;
    }
};

pub const FeatureExtractor = struct {
    allocator: std.mem.Allocator,
    window_size: usize,
    history: std.ArrayList(f64),
    
    pub fn init(allocator: std.mem.Allocator, window_size: usize) !*FeatureExtractor {
        const extractor = try allocator.create(FeatureExtractor);
        extractor.* = FeatureExtractor{
            .allocator = allocator,
            .window_size = window_size,
            .history = std.ArrayList(f64).init(allocator),
        };
        return extractor;
    }
    
    pub fn deinit(self: *FeatureExtractor) void {
        self.history.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn addSample(self: *FeatureExtractor, value: f64) !void {
        try self.history.append(value);
        
        if (self.history.items.len > self.window_size) {
            _ = self.history.orderedRemove(0);
        }
    }
    
    pub fn extractFeatures(self: *FeatureExtractor) ![]f64 {
        if (self.history.items.len == 0) {
            return error.InsufficientData;
        }
        
        var features = try self.allocator.alloc(f64, 10);
        
        var sum: f64 = 0.0;
        var min_val: f64 = self.history.items[0];
        var max_val: f64 = self.history.items[0];
        
        for (self.history.items) |val| {
            sum += val;
            if (val < min_val) min_val = val;
            if (val > max_val) max_val = val;
        }
        
        const mean = sum / @as(f64, @floatFromInt(self.history.items.len));
        
        var variance: f64 = 0.0;
        for (self.history.items) |val| {
            const diff = val - mean;
            variance += diff * diff;
        }
        variance /= @as(f64, @floatFromInt(self.history.items.len));
        const std_dev = @sqrt(variance);
        
        features[0] = mean;
        features[1] = std_dev;
        features[2] = min_val;
        features[3] = max_val;
        features[4] = max_val - min_val;
        features[5] = if (self.history.items.len > 0) self.history.items[self.history.items.len - 1] else 0.0;
        features[6] = if (self.history.items.len > 1) self.history.items[self.history.items.len - 1] - self.history.items[self.history.items.len - 2] else 0.0;
        features[7] = sum;
        features[8] = @as(f64, @floatFromInt(self.history.items.len));
        features[9] = variance;
        
        return features;
    }
};

pub const TinyMLEngine = struct {
    allocator: std.mem.Allocator,
    models: std.StringHashMap(*TinyMLModel),
    feature_extractors: std.StringHashMap(*FeatureExtractor),
    
    pub fn init(allocator: std.mem.Allocator) !*TinyMLEngine {
        const engine = try allocator.create(TinyMLEngine);
        engine.* = TinyMLEngine{
            .allocator = allocator,
            .models = std.StringHashMap(*TinyMLModel).init(allocator),
            .feature_extractors = std.StringHashMap(*FeatureExtractor).init(allocator),
        };
        return engine;
    }
    
    pub fn deinit(self: *TinyMLEngine) void {
        var model_iter = self.models.valueIterator();
        while (model_iter.next()) |model| {
            model.*.deinit();
        }
        self.models.deinit();
        
        var extractor_iter = self.feature_extractors.valueIterator();
        while (extractor_iter.next()) |extractor| {
            extractor.*.deinit();
        }
        self.feature_extractors.deinit();
        
        self.allocator.destroy(self);
    }
    
    pub fn loadModel(self: *TinyMLEngine, name: []const u8, path: []const u8, model_type: ModelType) !void {
        const model = try TinyMLModel.init(self.allocator, path, model_type);
        try model.load();
        try self.models.put(name, model);
        
        const extractor = try FeatureExtractor.init(self.allocator, 50);
        try self.feature_extractors.put(name, extractor);
    }
    
    pub fn predictAnomaly(self: *TinyMLEngine, model_name: []const u8, sensor_value: f64) !InferenceResult {
        const extractor = self.feature_extractors.get(model_name) orelse return error.ExtractorNotFound;
        const model = self.models.get(model_name) orelse return error.ModelNotFound;
        
        try extractor.addSample(sensor_value);
        
        const features = try extractor.extractFeatures();
        defer self.allocator.free(features);
        
        return try model.predict(features);
    }
};

