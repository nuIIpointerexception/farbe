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

        const one_minus_self_alpha = 255 - self.a;
        const other_alpha_scaled = @as(u16, other.a) * one_minus_self_alpha;

        const final_alpha = @as(u16, self.a) + other_alpha_scaled / 255;
        if (final_alpha == 0) return .{ .r = 0, .g = 0, .b = 0, .a = 0 };

        const inverse_final_alpha = @divTrunc(255 * 256, final_alpha);
        const blend_factor = other_alpha_scaled / 255;

        const r = (self.r * self.a + other.r * blend_factor) * inverse_final_alpha >> 8;
        const g = (self.g * self.a + other.g * blend_factor) * inverse_final_alpha >> 8;
        const b = (self.b * self.a + other.b * blend_factor) * inverse_final_alpha >> 8;

        return .{
            .r = @intCast(math.clamp(r, 0, 255)),
            .g = @intCast(math.clamp(g, 0, 255)),
            .b = @intCast(math.clamp(b, 0, 255)),
            .a = @intCast(math.clamp(final_alpha, 0, 255)),
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
        if (string.len < 7 or string[0] != '#') return error.InvalidFormat;

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
        _ = valid.String(string);

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
    pub fn fromHsla(color: @import("hsla.zig").HSLA) RGBA {
        if (color.s == 0.0) {
            const v = @as(u8, @intFromFloat(color.l * 255.0));
            return .{ .r = v, .g = v, .b = v, .a = @intFromFloat(color.a * 255.0) };
        }

        const q = if (color.l < 0.5)
            color.l * (1.0 + color.s)
        else
            color.l + color.s - color.l * color.s;
        const p = 2.0 * color.l - q;
        const h_adj = color.h * 6.0;

        const hueToRgb = struct {
            inline fn calc(t: f32, pp: f32, qq: f32) u8 {
                const tt = if (t < 0.0) t + 6.0 else if (t >= 6.0) t - 6.0 else t;
                const v = if (tt < 1.0)
                    pp + (qq - pp) * tt
                else if (tt < 3.0)
                    qq
                else if (tt < 4.0)
                    pp + (qq - pp) * (4.0 - tt)
                else
                    pp;
                return @intFromFloat(v * 255.0);
            }
        }.calc;

        return .{
            .r = hueToRgb(h_adj + 2.0, p, q),
            .g = hueToRgb(h_adj, p, q),
            .b = hueToRgb(h_adj + 4.0, p, q),
            .a = @intFromFloat(color.a * 255.0),
        };
    }

    /// Converts this `Rgba` color to an `Hsla` color.
    ///
    /// This function converts a color from the RGBA color space to the HSLA
    /// (Hue, Saturation, Lightness, Alpha) color space.
    pub fn toHsla(self: RGBA) @import("hsla.zig").HSLA {
        const rf = @as(f32, @floatFromInt(self.r)) / 255.0;
        const gf = @as(f32, @floatFromInt(self.g)) / 255.0;
        const bf = @as(f32, @floatFromInt(self.b)) / 255.0;
        const af = @as(f32, @floatFromInt(self.a)) / 255.0;

        if (self.r == self.g and self.g == self.b) {
            return .{ .h = 0, .s = 0, .l = rf, .a = af };
        }

        const max = @max(rf, @max(gf, bf));
        const min = @min(rf, @min(gf, bf));
        const delta = max - min;
        const l = (max + min) * 0.5;

        const s = if (l <= 0.5)
            delta / (max + min)
        else
            delta / (2.0 - max - min);

        const h = switch (@as(u2, @intFromBool(max == rf)) | (@as(u2, @intFromBool(max == gf)) << 1)) {
            0b01 => @mod((gf - bf) / delta, 6.0) / 6.0,
            0b10 => ((bf - rf) / delta + 2.0) / 6.0,
            else => ((rf - gf) / delta + 4.0) / 6.0,
        };

        return .{ .h = h, .s = s, .l = l, .a = af };
    }

    /// Converts this `Rgba` color to an `Hsv` color.
    ///
    /// This function creates a new `Rgba` color from an `Hsv` color.
    pub fn fromHsv(color: @import("hsv.zig").HSV) RGBA {
        const h = color.h * 6.0;
        const s = color.s;
        const v = color.v;

        if (s <= 0) {
            const val: u8 = @intFromFloat(@round(v * 255.0));
            return .{ .r = val, .g = val, .b = val, .a = @intFromFloat(@round(color.a * 255.0)) };
        }

        const sector = @as(u3, @intFromFloat(@floor(h)));
        const f = h - @floor(h);
        const p = v * (1.0 - s);
        const q = v * (1.0 - s * f);
        const t = v * (1.0 - s * (1.0 - f));

        const rgb = switch (sector) {
            0 => .{ v, t, p },
            1 => .{ q, v, p },
            2 => .{ p, v, t },
            3 => .{ p, q, v },
            4 => .{ t, p, v },
            else => .{ v, p, q },
        };

        return .{ .r = @intFromFloat(@round(rgb[0] * 255.0)), .g = @intFromFloat(@round(rgb[1] * 255.0)), .b = @intFromFloat(@round(rgb[2] * 255.0)), .a = @intFromFloat(@round(color.a * 255.0)) };
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
        if (delta != 0) {
            h = switch (@as(u2, @intFromBool(max == r)) | (@as(u2, @intFromBool(max == g)) << 1)) {
                0b01 => 60.0 * @mod((g - b) / delta, 6.0),
                0b10 => 60.0 * ((b - r) / delta + 2.0),
                else => 60.0 * ((r - g) / delta + 4.0),
            };
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
