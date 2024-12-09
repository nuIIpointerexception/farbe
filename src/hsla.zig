const std = @import("std");
const math = std.math;
const Vector = std.builtin.Type.Vector;

const RGBA = @import("rgba.zig").RGBA;
const valid = @import("valid.zig");

/// Represents a color in the HSLA format.
pub const HSLA = extern struct {
    /// The hue component of the color (0.0-360.0).
    h: f32,
    /// The saturation component of the color (0.0-1.0).
    s: f32,
    /// The lightness component of the color (0.0-1.0).
    l: f32,
    /// The alpha component of the color (0.0-1.0).
    a: f32,

    /// Initializes a new `Hsla` color with the given hue, saturation, lightness, and alpha components.
    pub fn init(h: f32, s: f32, l: f32, a: f32) @This() {
        return .{
            .h = h,
            .s = s,
            .l = l,
            .a = a,
        };
    }

    /// Converts this `Hsla` color to an `Rgba` color.
    ///
    /// This function converts a color from the HSLA color space to the RGBA color space.
    pub fn toRgba(self: @This()) RGBA {
        var normalized = self;
        normalized.h = self.h / 360.0;
        return RGBA.fromHsla(normalized);
    }

    // Converts this `Hsla` color to an `Hsv` color.
    pub fn toHsv(self: @This()) @import("hsv.zig").HSV {
        const l = self.l;
        const v = l + self.s * @min(l, 1 - l);
        const s = if (v == 0) 0 else 2 * (1 - l / v);
        return .{ .h = self.h, .s = s, .v = v, .a = self.a };
    }

    /// Blends this color with another color using alpha-weighted interpolation in HSLA space.
    ///
    /// The blending algorithm performs the following steps:
    /// 1. Handles hue interpolation by finding the shortest path around the color wheel
    /// 2. Linearly interpolates saturation, lightness, and alpha values
    /// 3. Uses a fixed 0.5 blend factor for a balanced mix of both colors
    ///
    /// For hue interpolation, special care is taken to handle the circular nature of hue values
    ///
    /// (0-360 degrees) by adjusting the difference to take the shortest path around the color wheel.
    pub fn blend(self: @This(), other: @This()) @This() {
        const HALF = 0.5;
        const h_diff = other.h - self.h;
        const adj = @floor((h_diff + 180.0) / 360.0) * 360.0;
        return .{
            .h = @mod(self.h + (h_diff - adj) * HALF, 360.0),
            .s = @mulAdd(f32, other.s - self.s, HALF, self.s),
            .l = @mulAdd(f32, other.l - self.l, HALF, self.l),
            .a = @mulAdd(f32, other.a - self.a, HALF, self.a),
        };
    }

    /// Returns a grayscale version of this `Hsla` color.
    ///
    /// This is achieved by setting the saturation component to 0.0.
    pub fn grayscale(self: *const @This()) @This() {
        return .{
            .h = self.h,
            .s = 0.0,
            .l = self.l,
            .a = self.a,
        };
    }

    /// Fades out this `Hsla` color by the given factor.
    ///
    /// The factor is clamped between 0.0 and 1.0. A factor of 0.0 results in no change,
    /// while a factor of 1.0 completely fades out the color (sets alpha to 0.0).
    pub fn fadeOut(self: *@This(), factor: f32) void {
        if (factor >= 1.0) {
            self.a = 0;
            return;
        }
        if (factor <= 0.0) return;

        self.a *= 1.0 - factor;
    }

    /// Returns a new `Hsla` color with the opacity adjusted by the given factor.
    ///
    /// The factor is clamped between 0.0 and 1.0. A factor of 0.0 results in a fully
    /// transparent color, while a factor of 1.0 results in no change to the opacity.
    pub fn opacity(self: *const @This(), factor: f32) @This() {
        const new_alpha = if (factor >= 1.0) self.a else if (factor <= 0.0) 0 else self.a * factor;

        return .{
            .h = self.h,
            .s = self.s,
            .l = self.l,
            .a = new_alpha,
        };
    }

    /// Creates a new `Hsla` color from an `Rgba` color.
    ///
    /// This function converts a color from the RGBA color space to the HSLA color space.
    pub fn fromRgba(color: RGBA) @This() {
        const r = @as(f32, @floatFromInt(color.r)) / 255.0;
        const g = @as(f32, @floatFromInt(color.g)) / 255.0;
        const b = @as(f32, @floatFromInt(color.b)) / 255.0;
        const a = @as(f32, @floatFromInt(color.a)) / 255.0;

        const max = @max(r, @max(g, b));
        const min = @min(r, @min(g, b));
        const delta = max - min;
        const sum = max + min;
        const l = sum * 0.5;

        var s: f32 = 0.0;
        if (delta != 0.0) {
            s = if (l <= 0.5) delta / sum else delta / (2.0 - sum);
        }

        var h: f32 = 0.0;
        if (delta != 0.0) {
            const delta_inv = 1.0 / delta;
            if (max == r) {
                h = @mod((g - b) * delta_inv, 6.0) / 6.0;
            } else if (max == g) {
                h = ((b - r) * delta_inv + 2.0) / 6.0;
            } else {
                h = ((r - g) * delta_inv + 4.0) / 6.0;
            }
        }

        return .{ .h = h * 360.0, .s = s, .l = l, .a = a };
    }
};
