const std = @import("std");
const win = std.os.windows;
const builtin = @import("builtin");

const ResultManager = @import("results.zig").ResultManager;

pub const Config = struct {
    name: []const u8,
    iterations: u32 = 10_000_000,
    warmup_iterations: u32 = 5_000_000,
    runs: u32 = 100,
    min_run_time_ns: u64 = 5_000_000,
};

pub const Result = struct {
    name: []const u8,
    iterations: u32,
    stats: Statistics,

    pub fn deinit(self: *Result, allocator: std.mem.Allocator) void {
        self.stats.deinit(allocator);
    }
};

pub const Statistics = struct {
    mean: f64,
    median: f64,
    std_dev: f64,
    min: f64,
    max: f64,
    samples: []const f64,

    pub fn deinit(self: *Statistics, allocator: std.mem.Allocator) void {
        allocator.free(self.samples);
    }
};

pub extern "kernel32" fn SetThreadPriority(hThread: ?win.HANDLE, nPriority: i32) callconv(win.WINAPI) win.BOOL;

fn setHighPriority() !void {
    if (builtin.os.tag == .windows) {
        _ = SetThreadPriority(win.GetCurrentThread(), 2);
    } else if (builtin.os.tag == .linux) {
        var param: std.os.linux.sched_param = .{ .sched_priority = 99 };
        try std.os.sched_setscheduler(0, std.os.linux.SCHED_FIFO, &param);
    }
}

pub fn run(allocator: std.mem.Allocator, comptime config: Config, func: anytype) !Result {
    try setHighPriority();

    var samples = try allocator.alloc(f64, config.runs);
    defer allocator.free(samples);

    for (0..config.warmup_iterations) |_| func();

    for (0..config.runs) |i| {
        var timer = try std.time.Timer.start();
        var iterations: u32 = 0;
        var total_time: u64 = 0;

        while (total_time < config.min_run_time_ns) : (iterations += 1) {
            timer.reset();
            func();
            total_time += timer.read();
        }
        samples[i] = @as(f64, @floatFromInt(total_time)) / @as(f64, @floatFromInt(iterations));
    }

    const sorted = samples;
    std.mem.sort(f64, sorted, {}, comptime std.sort.asc(f64));

    var sum: f64 = 0;
    var min = sorted[0];
    var max = sorted[0];
    for (sorted) |s| {
        sum += s;
        min = @min(min, s);
        max = @max(max, s);
    }

    const mean = sum / @as(f64, @floatFromInt(sorted.len));
    var vsum: f64 = 0;
    for (sorted) |s| {
        const d = s - mean;
        vsum += d * d;
    }

    return Result{
        .name = config.name,
        .iterations = config.iterations,
        .stats = .{
            .mean = mean,
            .median = sorted[sorted.len / 2],
            .std_dev = @sqrt(vsum / @as(f64, @floatFromInt(sorted.len - 1))),
            .min = min,
            .max = max,
            .samples = try allocator.dupe(f64, samples),
        },
    };
}

pub fn print(allocator: std.mem.Allocator, result: Result) void {
    const cv = result.stats.std_dev / result.stats.mean * 100.0;
    if (ResultManager.compareWithPrevious(&result)) |cmp| {
        const pct = cmp.improvement * 100;
        const significant = @abs(pct) >= 5;

        var text: []const u8 = "";
        defer if (text.len > 0) allocator.free(text);

        if (significant) {
            if (pct >= 0) {
                text = std.fmt.allocPrint(allocator, " \x1b[38;2;50;255;50m(+{d:>5.1}%)\x1b[0m", .{pct}) catch "";
            } else {
                text = std.fmt.allocPrint(allocator, " \x1b[38;2;255;50;50m({d:>5.1}%)\x1b[0m", .{pct}) catch "";
            }
        }

        std.debug.print("{s:<20} {d:>8.2}ns/op (+/-{d:>5.2}%) [{d:.2}ns..{d:.2}ns]{s}\n", .{
            result.name,
            result.stats.median,
            cv,
            result.stats.min,
            result.stats.max,
            text,
        });
    } else std.debug.print("{s:<20} {d:>8.2}ns/op (+/-{d:>5.2}%) [{d:.2}ns..{d:.2}ns]\n", .{
        result.name,
        result.stats.median,
        cv,
        result.stats.min,
        result.stats.max,
    });
}
