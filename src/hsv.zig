const HSLA = @import("hsla.zig").HSLA;
const RGBA = @import("rgba.zig").RGBA;

/// Represents a color in the HSV format.
pub const HSV = extern struct {
    /// The hue component of the color (0.0-360.0).
    h: f32,
    /// The saturation component of the color (0.0-1.0).
    s: f32,
    /// The value component of the color (0.0-1.0).
    v: f32,
    /// The alpha component of the color (0.0-1.0).
    a: f32,

    /// Initializes a new `Hsv` color with the given hue, saturation, value, and alpha components.
    pub fn init(h: f32, s: f32, v: f32, a: f32) HSV {
        return .{ .h = h, .s = s, .v = v, .a = a };
    }

    /// Blends this color with another color using alpha-weighted interpolation in HSV space.
    pub fn blend(self: HSV, other: HSV) HSV {
        const HALF = 0.5;
        const h_diff = other.h - self.h;
        const adj = @floor((h_diff + 180.0) / 360.0) * 360.0;
        return .{
            .h = @mod(self.h + (h_diff - adj) * HALF, 360.0),
            .s = @mulAdd(f32, other.s - self.s, HALF, self.s),
            .v = @mulAdd(f32, other.v - self.v, HALF, self.v),
            .a = @mulAdd(f32, other.a - self.a, HALF, self.a),
        };
    }

    /// Returns a grayscale version of this `Hsv` color.
    pub fn grayscale(self: *const HSV) HSV {
        return .{
            .h = self.h,
            .s = 0.0,
            .v = self.v,
            .a = self.a,
        };
    }

    /// Fades out this `Hsv` color by the given factor.
    ///
    /// 1.0 is fully opaque, 0.0 is fully transparent.
    pub fn fadeOut(self: *HSV, factor: f32) void {
        if (factor >= 1.0) {
            self.a = 0;
            return;
        }
        if (factor <= 0.0) return;
        self.a *= 1.0 - factor;
    }

    /// Returns a new `Hsv` color with the opacity adjusted by the given factor.
    ///
    /// 1.0 is fully opaque, 0.0 is fully transparent.
    pub fn opacity(self: *const HSV, factor: f32) HSV {
        const new_alpha = if (factor >= 1.0) self.a else if (factor <= 0.0) 0 else self.a * factor;
        return .{
            .h = self.h,
            .s = self.s,
            .v = self.v,
            .a = new_alpha,
        };
    }

    /// Creates a new `Hsv` color from an `Rgba` color.
    ///
    /// This function converts a color from the RGBA color space to the HSV color space.
    pub fn fromRgba(rgba: RGBA) HSV {
        const r = @as(f32, @floatFromInt(rgba.r)) / 255.0;
        const g = @as(f32, @floatFromInt(rgba.g)) / 255.0;
        const b = @as(f32, @floatFromInt(rgba.b)) / 255.0;
        const a = @as(f32, @floatFromInt(rgba.a)) / 255.0;

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

    /// Converts this `Hsv` color to an `Rgba` color.
    ///
    /// This function converts a color from the HSV color space to the RGBA color space.
    pub fn toRgba(self: HSV) RGBA {
        if (self.s <= 0.0) {
            const val: u8 = @intFromFloat(@round(self.v * 255.0));
            return .{ .r = val, .g = val, .b = val, .a = @intFromFloat(@round(self.a * 255.0)) };
        }

        const h = @mod(self.h, 360.0) / 60.0;
        const sector = @as(u3, @intFromFloat(@floor(h)));
        const f = h - @floor(h);

        const pqt = .{
            self.v * (1.0 - self.s),
            self.v * (1.0 - self.s * f),
            self.v * (1.0 - self.s * (1.0 - f)),
        };

        const rgb = switch (sector) {
            0 => .{ self.v, pqt[2], pqt[0] },
            1 => .{ pqt[1], self.v, pqt[0] },
            2 => .{ pqt[0], self.v, pqt[2] },
            3 => .{ pqt[0], pqt[1], self.v },
            4 => .{ pqt[2], pqt[0], self.v },
            else => .{ self.v, pqt[0], pqt[1] },
        };

        const factor: f32 = 255.0;
        return .{
            .r = @intFromFloat(@round(rgb[0] * factor)),
            .g = @intFromFloat(@round(rgb[1] * factor)),
            .b = @intFromFloat(@round(rgb[2] * factor)),
            .a = @intFromFloat(@round(self.a * factor)),
        };
    }

    /// Creates a new `Hsv` color from an `Hsla` color.
    ///
    /// This function converts a color from the HSLA color space to the HSV color space.
    pub fn fromHsla(hsla: HSLA) HSV {
        const l = hsla.l;
        const v = l + hsla.s * @min(l, 1 - l);
        const s = if (v == 0) 0 else 2 * (1 - l / v);
        return .{ .h = hsla.h, .s = s, .v = v, .a = hsla.a };
    }

    /// Converts this `Hsv` color to an `Hsla` color.
    ///
    /// This function converts a color from the HSV color space to the HSLA color space.
    pub fn toHsla(self: HSV) HSLA {
        const v = self.v;
        const s = self.s;
        const l = v * (1 - s / 2);
        const sl = if (l == 0 or l == 1)
            0
        else
            (v - l) / @min(l, 1 - l);

        return .{ .h = self.h, .s = sl, .l = l, .a = self.a };
    }
};
