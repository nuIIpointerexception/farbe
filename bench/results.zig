const std = @import("std");

pub const StoredResult = struct {
    name: []const u8,
    median: f64,
    min: f64,
    max: f64,
};

pub const CompareResult = struct {
    name: []const u8,
    current_median: f64,
    prev_median: f64,
    improvement: f64,

    pub fn getColor(self: CompareResult) [4]u8 {
        return if (self.improvement > 0)
            .{ 50, 255, 50, 255 }
        else if (self.improvement < -0.2)
            .{ @intFromFloat(@abs(self.improvement * 255)), 0, 0, 255 }
        else
            .{ 255, 255, 0, 255 };
    }
};

pub const ResultManager = struct {
    const SavePath = "bench_results.bin";
    var results: std.StringHashMap(StoredResult) = undefined;
    var initialized = false;

    pub fn init(allocator: std.mem.Allocator) !void {
        if (!initialized) {
            results = std.StringHashMap(StoredResult).init(allocator);
            initialized = true;

            const file = std.fs.cwd().openFile(SavePath, .{}) catch |err| switch (err) {
                error.FileNotFound => return,
                else => |e| return e,
            };
            defer file.close();

            var reader = file.reader();
            const count = try reader.readInt(usize, .little);
            var i: usize = 0;
            errdefer {
                var it = results.iterator();
                while (it.next()) |entry| {
                    allocator.free(entry.value_ptr.name);
                }
                results.deinit();
                initialized = false;
            }

            while (i < count) : (i += 1) {
                const name_len = try reader.readInt(usize, .little);
                const name = try results.allocator.alloc(u8, name_len);
                errdefer results.allocator.free(name);

                try reader.readNoEof(name);
                const median = @as(f64, @bitCast(try reader.readInt(u64, .little)));
                const min = @as(f64, @bitCast(try reader.readInt(u64, .little)));
                const max = @as(f64, @bitCast(try reader.readInt(u64, .little)));

                try results.put(name, .{
                    .name = name,
                    .median = median,
                    .min = min,
                    .max = max,
                });
            }
        }
    }

    pub fn deinit(allocator: std.mem.Allocator) void {
        if (initialized) {
            var it = results.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.value_ptr.name);
            }
            results.deinit();
            initialized = false;
        }
    }

    pub fn saveResult(result: *const @import("bench.zig").Result) !void {
        if (!initialized) return error.NotInitialized;

        const name_copy = try results.allocator.dupe(u8, result.name);
        errdefer results.allocator.free(name_copy);

        if (results.fetchRemove(result.name)) |kv| {
            results.allocator.free(kv.value.name);
        }

        try results.put(name_copy, .{
            .name = name_copy,
            .median = result.stats.median,
            .min = result.stats.min,
            .max = result.stats.max,
        });
    }

    pub fn compareWithPrevious(result: *const @import("bench.zig").Result) ?CompareResult {
        if (!initialized) return null;
        const prev = results.get(result.name);
        if (prev) |p| {
            const improvement = (p.median - result.stats.median) / p.median;
            return .{
                .name = result.name,
                .current_median = result.stats.median,
                .prev_median = p.median,
                .improvement = improvement,
            };
        }
        return null;
    }

    pub fn writeToFile(allocator: std.mem.Allocator) !void {
        _ = allocator; // autofix
        const file = try std.fs.cwd().createFile(SavePath, .{});
        defer file.close();
        var writer = file.writer();

        try writer.writeInt(usize, results.count(), .little);

        var it = results.iterator();
        while (it.next()) |entry| {
            try writer.writeInt(usize, entry.key_ptr.len, .little);
            try writer.writeAll(entry.key_ptr.*);
            try writer.writeInt(u64, @bitCast(entry.value_ptr.median), .little);
            try writer.writeInt(u64, @bitCast(entry.value_ptr.min), .little);
            try writer.writeInt(u64, @bitCast(entry.value_ptr.max), .little);
        }
    }
};
