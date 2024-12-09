const std = @import("std");

const farbe = @import("farbe");
const Rgba = farbe.RGBA;
const Hsla = farbe.HSLA;

pub var result_sink = std.atomic.Value(u64).init(0);

pub const ColorBench = struct {
    inline fn getTimestampAbs() u64 {
        return @bitCast(@abs(std.time.timestamp()));
    }

    pub fn hslaToRgba() void {
        const timestamp = getTimestampAbs();
        const hsla = Hsla.init(@floatFromInt(timestamp % 360), 0.5, 0.5, 1.0);
        result_sink.store(@as(u64, hsla.toRgba().r), .monotonic);
    }

    pub fn rgbaToHsla() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        result_sink.store(@as(u64, @intFromFloat(rgba.toHsla().h)), .monotonic);
    }

    pub fn rgbaBlend() void {
        const timestamp = getTimestampAbs();
        const r: u8 = @intCast(timestamp % 256);
        result_sink.store(@as(u64, Rgba.init(r, 128, 128, 255).blend(Rgba.init(
            (r +% 128) & 0xFF,
            128,
            128,
            255,
        )).r), .monotonic);
    }

    pub fn rgbaBlendMultiple() void {
        const r: u8 = @intCast(getTimestampAbs() % 256);
        var colors: [2][4]Rgba = undefined;
        comptime var i: u8 = 0;
        inline while (i < 4) : (i += 1) {
            colors[0][i] = Rgba.init(r +% i, 128, 128, 255);
            colors[1][i] = Rgba.init(255 -% r -% i, 128, 128, 255);
        }
        result_sink.store(@as(
            u64,
            Rgba.blendMultiple(4, colors[0], colors[1])[0].r,
        ), .monotonic);
    }

    pub fn rgbaFromStr() void {
        const timestamp = getTimestampAbs();
        const r: u8 = @intCast(timestamp % 256);
        // Convert u8 to string buffer
        var hex_buf: [2]u8 = undefined;
        _ = std.fmt.bufPrint(&hex_buf, "{x:0>2}", .{r}) catch unreachable;
        const color_str = "#" ++ &hex_buf ++ &hex_buf ++ &hex_buf ++ &hex_buf;
        const rgba = Rgba.fromStr(color_str) catch unreachable;
        result_sink.store(@as(u64, rgba.r), .monotonic);
    }

    pub fn fromHsla() void {
        const timestamp = getTimestampAbs();
        const hsla = Hsla.init(@floatFromInt(timestamp % 360), 0.5, 0.5, 1.0);
        result_sink.store(@as(u64, hsla.toRgba().r), .monotonic);
    }
};
