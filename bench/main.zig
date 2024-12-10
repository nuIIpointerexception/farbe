const std = @import("std");

const bench = @import("bench.zig");
const ResultManager = @import("results.zig").ResultManager;

const benchmarks = struct {
    pub const rgba = @import("impl/rgba.zig").RgbaBench;
};

const BenchFn = struct {
    name: []const u8,
    func: fn () void,
};

// Simplified benchmark function discovery
fn getBenchmarkFns(comptime T: type) []const BenchFn {
    const type_info = @typeInfo(T);
    if (type_info != .@"struct") {
        if (type_info == .type) {
            // Handle type references
            return getBenchmarkFns(@TypeOf(@as(T, undefined)));
        }
        return &.{};
    }

    comptime {
        var fns: []const BenchFn = &.{};
        for (type_info.Struct.decls) |decl| {
            const field = @field(T, decl.name);
            const field_type = @TypeOf(field);

            if (@typeInfo(field_type) == .Fn) {
                const fn_info = @typeInfo(field_type).Fn;
                if (fn_info.params.len == 0) {
                    fns = fns ++ &[_]BenchFn{.{
                        .name = decl.name,
                        .func = field,
                    }};
                }
            }
        }
        return fns;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try ResultManager.init(allocator);
    defer ResultManager.deinit(allocator);

    std.debug.print("\nBenchmark Results:\n", .{});
    std.debug.print("--------------------------------------------------------------------------------\n", .{});

    // Process benchmarks using comptime iteration
    comptime {
        for (@typeInfo(benchmarks).@"struct".decls) |decl| {
            const module = @field(benchmarks, decl.name);
            const bench_fns = getBenchmarkFns(@TypeOf(module));

            std.debug.print("\n{s} Benchmarks:\n", .{decl.name});

            for (bench_fns) |bench_fn| {
                const config = bench.Config{ .name = bench_fn.name };
                var result = try bench.run(allocator, config, bench_fn.func);
                try bench.print(allocator, result);
                try ResultManager.saveResult(&result);
                result.deinit(allocator);
            }
        }
    }

    try ResultManager.writeToFile(allocator);
}
