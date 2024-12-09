const std = @import("std");

const bench = @import("bench.zig");
const color_bench = @import("impl/color.zig");
const ResultManager = @import("results.zig").ResultManager;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try ResultManager.init(allocator);
    defer ResultManager.deinit(allocator);

    const configs = .{
        bench.Config{ .name = "HSLA -> RGBA" },
        bench.Config{ .name = "RGBA -> HSLA" },
        bench.Config{ .name = "RGBA Blend" },
        bench.Config{ .name = "RGBA Blend Multiple" },
        bench.Config{ .name = "RGBA from HSLA" },
        bench.Config{ .name = "RGBA from string" },
    };

    std.debug.print("\nfarbe.zig: iterations={d}\n", .{
        configs[0].iterations,
    });
    std.debug.print("--------------------------------------------------------------------------------\n", .{});

    inline for (configs, 0..) |config, i| {
        var result = try bench.run(allocator, config, switch (i) {
            0 => color_bench.ColorBench.hslaToRgba,
            1 => color_bench.ColorBench.rgbaToHsla,
            2 => color_bench.ColorBench.rgbaBlend,
            3 => color_bench.ColorBench.rgbaBlendMultiple,
            4 => color_bench.ColorBench.fromHsla,
            5 => color_bench.ColorBench.rgbaFromStr,

            else => unreachable,
        });
        bench.print(allocator, result);
        try ResultManager.saveResult(&result);
        result.deinit(allocator);
    }

    try ResultManager.writeToFile(allocator);
}
