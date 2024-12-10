const std = @import("std");

const farbe = @import("farbe");
const Rgba = farbe.RGBA;
const Hsla = farbe.HSLA;

pub var result_sink = std.atomic.Value(u64).init(0);

pub const RgbaBench = struct {
    inline fn getTimestampAbs() u64 {
        return @bitCast(@abs(std.time.timestamp()));
    }

    pub fn init() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        result_sink.store(@as(u64, rgba.r), .monotonic);
    }

    pub fn fromHex() void {
        const timestamp = getTimestampAbs();
        const r: u8 = @intCast(timestamp % 256);
        var hex_buf: [2]u8 = undefined;
        _ = std.fmt.bufPrint(&hex_buf, "{x:0>2}", .{r}) catch unreachable;
        const color_str = "#" ++ &hex_buf ++ &hex_buf ++ &hex_buf ++ &hex_buf;
        const rgba = Rgba.fromStr(color_str) catch unreachable;
        result_sink.store(@as(u64, rgba.r), .monotonic);
    }

    pub fn blend() void {
        const timestamp = getTimestampAbs();
        const r: u8 = @intCast(timestamp % 256);
        const color1 = Rgba.init(r, 128, 128, 255);
        const color2 = Rgba.init((r +% 128) & 0xFF, 128, 128, 255);
        const result = color1.blend(color2);
        result_sink.store(@as(u64, result.r), .monotonic);
    }

    pub fn blendMultiple() void {
        const r: u8 = @intCast(getTimestampAbs() % 256);
        var colors1: [4]Rgba align(16) = undefined;
        var colors2: [4]Rgba align(16) = undefined;

        comptime var i: u8 = 0;
        inline while (i < 4) : (i += 1) {
            colors1[i] = Rgba.init(r +% i, 128, 128, 255);
            colors2[i] = Rgba.init(255 -% r -% i, 128, 128, 255);
        }

        const results = Rgba.blendMultiple(4, &colors1, &colors2);
        result_sink.store(@as(u64, results[0].r), .monotonic);
    }

    pub fn toHsla() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        const hsla = rgba.toHsla();
        result_sink.store(@as(u64, @intFromFloat(hsla.h)), .monotonic);
    }

    pub fn fromHsla() void {
        const timestamp = getTimestampAbs();
        const hsla = Hsla.init(@floatFromInt(timestamp % 360), 0.5, 0.5, 1.0);
        const rgba = hsla.toRgba();
        result_sink.store(@as(u64, rgba.r), .monotonic);
    }

    pub fn grayscale() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        const gray = rgba.grayscale();
        result_sink.store(@as(u64, gray.r), .monotonic);
    }

    pub fn opacity() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        const factor = @as(f32, @floatFromInt(timestamp % 100)) / 100.0;
        const result = rgba.opacity(factor);
        result_sink.store(@as(u64, result.a), .monotonic);
    }

    pub fn toU32() void {
        const timestamp = getTimestampAbs();
        const rgba = Rgba.init(@intCast(timestamp % 256), 128, 128, 255);
        const u32_value = rgba.toU32();
        result_sink.store(u32_value, .monotonic);
    }

    pub fn blendAlpha() void {
        const timestamp = getTimestampAbs();
        const r: u8 = @intCast(timestamp % 256);
        const color1 = Rgba.init(r, 128, 128, 128);
        const color2 = Rgba.init((r +% 128) & 0xFF, 128, 128, 128);
        const result = color1.blend(color2);
        result_sink.store(@as(u64, result.a), .monotonic);
    }
};