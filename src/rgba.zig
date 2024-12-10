const std = @import("std");
const math = std.math;

const hex = @import("hex.zig");
const valid = @import("valid.zig");

/// Represents a color in the RGBA format.
pub const RGBA = packed struct {
    /// The red component of the color (0-255).
    r: u8,
    /// The green component of the color (0-255).
    g: u8,
    /// The blue component of the color (0-255).
    b: u8,
    /// The alpha component of the color (0-255).
    a: u8 = 255,

    /// Initializes a new `Rgba` color with the given red, green, blue, and alpha components.
    pub fn init(r: u8, g: u8, b: u8, a: u8) RGBA {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Blends this color with another color, taking into account their alpha values.
    pub fn blend(self: RGBA, other: RGBA) RGBA {
        if (self.a == 255 and other.a == 255) {
            return .{
                .r = @intCast((self.r + other.r) >> 1),
                .g = @intCast((self.g + other.g) >> 1),
                .b = @intCast((self.b + other.b) >> 1),
                .a = 255,
            };
        }

        if (other.a == 0) return self;
        if (self.a == 0) return other;

        // For 50% transparency, we want exactly half of each color
        const sa = @as(u32, self.a);
        const oa = @as(u32, other.a);

        // Scale everything up by 256 for precise integer math
        const factor = (oa * 256) / 255;
        const inv_factor = 256 - factor;

        const r = (@as(u32, self.r) * inv_factor + @as(u32, other.r) * factor + 128) >> 8;
        const g = (@as(u32, self.g) * inv_factor + @as(u32, other.g) * factor + 128) >> 8;
        const b = (@as(u32, self.b) * inv_factor + @as(u32, other.b) * factor + 128) >> 8;

        const a = @min(255, (sa * 256 + (255 - sa) * oa + 128) >> 8);

        return .{
            .r = @intCast(r),
            .g = @intCast(g),
            .b = @intCast(b),
            .a = @intCast(a),
        };
    }

    /// Blends multiple pairs of colors simultaneously using SIMD instructions.
    ///
    /// This function leverages SIMD (Single Instruction, Multiple Data) instructions to
    /// perform alpha blending on multiple pairs of colors in parallel. This can significantly
    /// improve performance when blending a large number of colors.
    ///
    /// If SIMD instructions are not available on the target architecture, this function falls
    /// back to the regular `Rgba.blend` implementation.
    pub fn blendMultiple(comptime N: usize, colors1: [N]RGBA, colors2: [N]RGBA) [N]RGBA {
        var result: [N]RGBA = undefined;

        if (@hasDecl(std.builtin.Type.Vector, "add")) {
            var i: usize = 0;
            while (i + 4 <= N) : (i += 4) {
                const r1 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors1[i].r, colors1[i + 1].r, colors1[i + 2].r, colors1[i + 3].r,
                }));
                const r2 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors2[i].r, colors2[i + 1].r, colors2[i + 2].r, colors2[i + 3].r,
                }));
                const g1 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors1[i].g, colors1[i + 1].g, colors1[i + 2].g, colors1[i + 3].g,
                }));
                const g2 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors2[i].g, colors2[i + 1].g, colors2[i + 2].g, colors2[i + 3].g,
                }));
                const b1 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors1[i].b, colors1[i + 1].b, colors1[i + 2].b, colors1[i + 3].b,
                }));
                const b2 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors2[i].b, colors2[i + 1].b, colors2[i + 2].b, colors2[i + 3].b,
                }));
                const a1 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors1[i].a, colors1[i + 1].a, colors1[i + 2].a, colors1[i + 3].a,
                }));
                const a2 = @as(@Vector(4, u8), @bitCast([4]u8{
                    colors2[i].a, colors2[i + 1].a, colors2[i + 2].a, colors2[i + 3].a,
                }));

                const blended_r = (r1 +% r2) >> @splat(@as(u3, 1));
                const blended_g = (g1 +% g2) >> @splat(@as(u3, 1));
                const blended_b = (b1 +% b2) >> @splat(@as(u3, 1));
                const blended_a = (a1 +% a2) >> @splat(@as(u3, 1));

                inline for (0..4) |j| {
                    result[i + j] = .{
                        .r = @as([4]u8, @bitCast(blended_r))[j],
                        .g = @as([4]u8, @bitCast(blended_g))[j],
                        .b = @as([4]u8, @bitCast(blended_b))[j],
                        .a = @as([4]u8, @bitCast(blended_a))[j],
                    };
                }
            }

            while (i < N) : (i += 1) {
                result[i] = colors1[i].blend(colors2[i]);
            }
        } else {
            for (0..N) |i| {
                result[i] = colors1[i].blend(colors2[i]);
            }
        }

        return result;
    }

    /// Converts this `Rgba` color to a `u32` value.
    pub fn toU32(self: RGBA) u32 {
        return @bitCast(self);
    }

    /// Creates a new `Rgba` color from a hexadecimal string.
    ///
    /// The string must be in the format `#RRGGBB` or `#RRGGBBAA`.
    ///
    /// If the string is not in a valid format, an error is returned.
    pub fn fromStr(string: []const u8) !RGBA {
        if ((string.len != 7 and string.len != 9) or string[0] != '#') {
            return error.InvalidFormat;
        }
        const r = try hex.parse(string[1..3]);
        const g = try hex.parse(string[3..5]);
        const b = try hex.parse(string[5..7]);
        var a: u8 = 255;

        if (string.len == 9) {
            a = try hex.parse(string[7..9]);
        }

        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Creates a new `Rgba` color from a hexadecimal string at compile time.
    ///
    /// The string must be in the format `#RRGGBB` or `#RRGGBBAA`.
    ///
    /// If the string is not in a valid format, a compile error is generated.
    pub fn comptimeFromStr(comptime string: []const u8) RGBA {
        _ = valid.IsHex(string);

        const parseHexPair = struct {
            fn parse(comptime str: []const u8, comptime offset: usize) u8 {
                const high = hex.toDigit(str[offset]);
                const low = hex.toDigit(str[offset + 1]);
                if (high == 0xff or low == 0xff)
                    @compileError("'" ++ str ++ "' is not a valid color");
                return high * 16 + low;
            }
        }.parse;

        const r = comptime parseHexPair(string, 1);
        const g = comptime parseHexPair(string, 3);
        const b = comptime parseHexPair(string, 5);
        const a = if (string.len == 9)
            comptime parseHexPair(string, 7)
        else
            255;

        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Creates a new `Rgba` color from an `Hsla` color.
    ///
    /// This function converts a color from the HSLA (Hue, Saturation, Lightness, Alpha)
    /// color space to the RGBA color space.
    pub fn fromHsla(hsla: @import("hsla.zig").HSLA) RGBA {
        if (hsla.s <= 0.0) {
            const v: u8 = @intFromFloat(hsla.l * 255.0);
            return .{ .r = v, .g = v, .b = v, .a = @intFromFloat(hsla.a * 255.0) };
        }

        const h_norm: f32 = @mod(hsla.h, 360.0) / 60.0;
        const sector: u3 = @intFromFloat(h_norm);
        const frac: f32 = h_norm - @as(f32, @floatFromInt(sector));

        const k: f32 = 1.0 - @abs(2.0 * hsla.l - 1.0);
        const chroma: f32 = k * hsla.s;
        const x: f32 = chroma * (1.0 - @abs(2.0 * frac - 1.0));
        const m: f32 = hsla.l - 0.5 * chroma;

        const rgb = switch (sector) {
            0 => .{ chroma, x, 0.0 },
            1 => .{ x, chroma, 0.0 },
            2 => .{ 0.0, chroma, x },
            3 => .{ 0.0, x, chroma },
            4 => .{ x, 0.0, chroma },
            else => .{ chroma, 0.0, x },
        };

        const m255: f32 = m * 255.0;

        return .{
            .r = @intFromFloat(rgb[0] * 255.0 + m255),
            .g = @intFromFloat(rgb[1] * 255.0 + m255),
            .b = @intFromFloat(rgb[2] * 255.0 + m255),
            .a = @intFromFloat(hsla.a * 255.0),
        };
    }

    /// Converts this `Rgba` color to an `Hsla` color.
    ///
    /// This function converts a color from the RGBA color space to the HSLA
    /// (Hue, Saturation, Lightness, Alpha) color space.
    pub fn toHsla(self: RGBA) @import("hsla.zig").HSLA {
        const inv255: f32 = 1.0 / 255.0;
        const rgb = .{
            @as(f32, @floatFromInt(self.r)) * inv255,
            @as(f32, @floatFromInt(self.g)) * inv255,
            @as(f32, @floatFromInt(self.b)) * inv255,
        };

        const max: f32 = @max(rgb[0], @max(rgb[1], rgb[2]));
        const min: f32 = @min(rgb[0], @min(rgb[1], rgb[2]));
        const diff: f32 = max - min;

        if (diff < 1e-6) {
            return .{
                .h = 0.0,
                .s = 0.0,
                .l = max,
                .a = @as(f32, @floatFromInt(self.a)) * inv255,
            };
        }

        const l: f32 = (max + min) * 0.5;
        const s: f32 = diff / (if (l <= 0.5) max + min else 2.0 - max - min);

        var h: f32 = undefined;
        if (max == rgb[0]) {
            h = (rgb[1] - rgb[2]) / diff;
            if (rgb[1] < rgb[2]) {
                h += 6.0;
            }
        } else if (max == rgb[1]) {
            h = (rgb[2] - rgb[0]) / diff + 2.0;
        } else {
            h = (rgb[0] - rgb[1]) / diff + 4.0;
        }
        h *= 60.0;

        return .{ .h = h, .s = s, .l = l, .a = @as(f32, @floatFromInt(self.a)) * inv255 };
    }

    /// Converts this `Rgba` color to an `Hsv` color.
    ///
    /// This function creates a new `Rgba` color from an `Hsv` color.
    pub fn fromHsv(color: @import("hsv.zig").HSV) RGBA {
        // Handle grayscale case
        if (color.s <= 0.0) {
            const val: u8 = @intFromFloat(@round(color.v * 255.0));
            return .{ .r = val, .g = val, .b = val, .a = @intFromFloat(@round(color.a * 255.0)) };
        }

        // Normalize hue to [0, 360) range
        const h = @mod(color.h, 360.0);
        const s = color.s;
        const v = color.v;

        // Instead of doing sector calculation, explicitly handle each 60° segment
        var r: f32 = undefined;
        var g: f32 = undefined;
        var b: f32 = undefined;

        const c = v * s;
        const x = c * (1.0 - @abs(@mod(h / 60.0, 2.0) - 1.0));
        const m = v - c;

        if (h < 60.0) {
            r = c;
            g = x;
            b = 0.0;
        } else if (h < 120.0) {
            r = x;
            g = c;
            b = 0.0;
        } else if (h < 180.0) {
            r = 0.0;
            g = c;
            b = x;
        } else if (h < 240.0) {
            r = 0.0;
            g = x;
            b = c;
        } else if (h < 300.0) {
            r = x;
            g = 0.0;
            b = c;
        } else {
            r = c;
            g = 0.0;
            b = x;
        }

        const rgb = .{
            .r = @as(u8, @intFromFloat(@round((r + m) * 255.0))),
            .g = @as(u8, @intFromFloat(@round((g + m) * 255.0))),
            .b = @as(u8, @intFromFloat(@round((b + m) * 255.0))),
            .a = @as(u8, @intFromFloat(@round(color.a * 255.0))),
        };

        return rgb;
    }

    /// Converts this `Rgba` color to an `Hsv` color.
    ///
    /// This function converts a color from the RGBA color space to the HSV color space.
    pub fn toHsv(self: RGBA) @import("hsv.zig").HSV {
        const r = @as(f32, @floatFromInt(self.r)) / 255.0;
        const g = @as(f32, @floatFromInt(self.g)) / 255.0;
        const b = @as(f32, @floatFromInt(self.b)) / 255.0;
        const a = @as(f32, @floatFromInt(self.a)) / 255.0;

        const max = @max(r, @max(g, b));
        const min = @min(r, @min(g, b));
        const delta = max - min;

        var h: f32 = 0;
        if (delta > 0) {
            h = if (max == r)
                60.0 * @mod((g - b) / delta, 6.0)
            else if (max == g)
                60.0 * ((b - r) / delta + 2.0)
            else
                60.0 * ((r - g) / delta + 4.0);
        }
        if (h < 0) h += 360;

        const s = if (max == 0) 0 else delta / max;

        return .{ .h = h, .s = s, .v = max, .a = a };
    }

    /// Returns a new `Rgba` color with the opacity adjusted by the given factor.
    ///
    /// The factor is clamped between 0.0 and 1.0. A factor of 0.0 results in a fully
    /// transparent color, while a factor of 1.0 results in no change to the opacity.
    pub fn opacity(self: RGBA, factor: f32) RGBA {
        if (factor >= 1.0) return self;
        if (factor <= 0.0) return .{ .r = self.r, .g = self.g, .b = self.b, .a = 0 };

        return .{
            .r = self.r,
            .g = self.g,
            .b = self.b,
            .a = @intFromFloat(@as(f32, @floatFromInt(self.a)) * factor),
        };
    }

    /// Fades out this `Rgba` color by the given factor.
    ///
    /// The factor is clamped between 0.0 and 1.0. A factor of 0.0 results in no change,
    /// while a factor of 1.0 completely fades out the color (sets alpha to 0.0).
    pub fn fadeOut(self: *RGBA, factor: f32) void {
        if (factor >= 1.0) {
            self.a = 0;
            return;
        }
        if (factor <= 0.0) return;
        const new_alpha = @as(f32, @floatFromInt(self.a)) * (1.0 - factor);
        self.a = @intFromFloat(new_alpha);
    }

    /// Returns a grayscale version of this `Rgba` color.
    ///
    /// This is achieved by setting the red, green, and blue components to the same value.
    pub fn grayscale(self: RGBA) RGBA {
        const gray_f = @as(f32, @floatFromInt(self.r)) * 0.2126 +
            @as(f32, @floatFromInt(self.g)) * 0.7152 +
            @as(f32, @floatFromInt(self.b)) * 0.0722;
        const gray_u8: u8 = @intFromFloat(gray_f);
        return .{ .r = gray_u8, .g = gray_u8, .b = gray_u8, .a = self.a };
    }
};
