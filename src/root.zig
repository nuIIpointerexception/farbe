const std = @import("std");
const math = std.math;

const hex = @import("hex.zig");
pub const HSLA = @import("hsla.zig").HSLA;
pub const HSV = @import("hsv.zig").HSV;
pub const RGBA = @import("rgba.zig").RGBA;
const valid = @import("valid.zig");

// TODO(viable): Add more color types (HSL, CMYK, etc.)

/// Creates a new `Rgba` color from various input formats.
///
/// Supports the following input formats:
/// - 4 integers as tuple: `rgba(.{255, 0, 0, 255})` for (r, g, b, a)
/// - Hex integer: `rgba(0xFF0000FF)` or `rgba(0xFF0000)` (alpha def
/// - Hex string: `rgba("#FF0000FF")` or `rgba("#FF0000")` (alpha defaults to FF)
/// - HSLA color: `rgba(hsla(0.0, 1.0, 0.5, 1.0))`
/// - HSLA values: `rgba(.{0.0, 1.0, 0.5, 1.0})`
///
/// Integer components are clamped to 0-255 range.
/// HSLA components are clamped to 0.0-1.0 range.
///
/// Returns:
/// - Compile error for invalid compile-time values
/// - Runtime error for invalid string formats or values
/// - `Rgba` color for valid inputs
///
/// Examples:
/// ```zig
/// const red1 = try rgba(.{255, 0, 0, 255});     // from RGBA integers
/// const red2 = try rgba(0xFF0000FF);            // from hex integer
/// const red3 = try rgba("#FF0000");             // from hex string
/// const red4 = try rgba(hsla(0.0, 1.0, 0.5, 1.0)); // from HSLA color
/// ```
pub fn Rgba(args: anytype) !RGBA {
    const ArgsType = @TypeOf(args);

    return switch (@typeInfo(ArgsType)) {
        .@"struct" => if (@typeInfo(ArgsType).@"struct".is_tuple) blk: {
            if (args.len != 4) {
                if (comptime true) {
                    @compileError("Expected 4 arguments (r, g, b, a) for RGBA color");
                } else {
                    return error.InvalidArgCount;
                }
            }
            break :blk RGBA{
                .r = math.clamp(@as(u8, @intCast(args[0])), 0, 255),
                .g = math.clamp(@as(u8, @intCast(args[1])), 0, 255),
                .b = math.clamp(@as(u8, @intCast(args[2])), 0, 255),
                .a = math.clamp(@as(u8, @intCast(args[3])), 0, 255),
            };
        } else if (ArgsType == HSLA or ArgsType == HSV) {
            return args.toRgba();
        } else if (comptime valid.Hsla(ArgsType)) blk: {
            const hsla_color = Hsla(args[0], args[1], args[2], if (args.len > 3) args[3] else 1.0);
            break :blk hsla_color.toRgba();
        } else error.UnsupportedStructType,

        .int, .comptime_int => blk: {
            if (args > 0xFFFFFFFF) {
                if (comptime true) {
                    @compileError("Hex code exceeds maximum value for RGBA (0xFFFFFFFF)");
                } else {
                    return error.InvalidHexValue;
                }
            }
            const r = (args >> 24) & 0xFF;
            const g = (args >> 16) & 0xFF;
            const b = (args >> 8) & 0xFF;
            const a = args & 0xFF;
            break :blk {
                break :blk if (args <= 0xFFFFFF)
                    RGBA{ .r = @intCast(r), .g = @intCast(g), .b = @intCast(b), .a = 0xFF }
                else
                    RGBA{ .r = @intCast(r), .g = @intCast(g), .b = @intCast(b), .a = @intCast(a) };
            };
        },

        .pointer => blk: {
            const child = @TypeOf(args.*);
            if (@typeInfo(child) == .array) {
                const array_info = @typeInfo(child).array;
                if (array_info.child == u8) {
                    break :blk RGBA.fromStr(args);
                }
            } else if (valid.ZigStr(child)) {
                break :blk RGBA.fromStr(args);
            }
            if (comptime true) {
                @compileError("Unsupported pointer type");
            } else {
                return error.UnsupportedPointerType;
            }
        },

        .array => blk: {
            const array_info = @typeInfo(ArgsType).array;
            if (array_info.child == u8) {
                break :blk RGBA.fromStr(&args);
            }
            if (comptime true) {
                @compileError("Unsupported array type");
            } else {
                return error.UnsupportedArrayType;
            }
        },

        else => if (comptime valid.ZigStr(ArgsType)) blk: {
            if (comptime std.mem.eql(u8, args, "")) {
                @compileError("Empty string is not a valid color");
            }
            break :blk RGBA.fromStr(args);
        } else if (comptime true) {
            @compileError("Expected integer, string type, or HSLA values, found " ++ @typeName(ArgsType));
        } else {
            return error.UnsupportedType;
        },
    };
}

/// Creates a new `Hsla` color with the given hue, saturation, lightness, and alpha components.
///
/// The `hue`, `saturation`, `lightness`, and `alpha` components can be either compile-time or runtime values.
///
/// If any of the components are not within the valid range (0.0-360.0 for hue, 0.0-1.0 for saturation and lightness, 0.0-1.0 for alpha),
/// a compile error is generated if they are compile-time values,
/// or they are clamped to the valid range if they are runtime values.
pub fn Hsla(hue: anytype, saturation: anytype, lightness: anytype, alpha: anytype) HSLA {
    const T = @TypeOf(hue);
    if (comptime !(@TypeOf(saturation) == T and @TypeOf(lightness) == T and @TypeOf(alpha) == T)) {
        @compileError("All arguments must have the same type");
    }

    if (comptime @typeInfo(T) == .comptime_float or @typeInfo(T) == .float) {
        return .{
            .h = math.clamp(hue, 0.0, 360.0),
            .s = math.clamp(saturation, 0.0, 1.0),
            .l = math.clamp(lightness, 0.0, 1.0),
            .a = math.clamp(alpha, 0.0, 1.0),
        };
    } else {
        @compileError("Arguments must be floats");
    }
}

/// Creates a new `HSV` color from various input formats.
///
/// Supports:
/// - 4 floats: `Hsv(360.0, 1.0, 1.0, 1.0)` for (h,s,v,a)
/// - RGBA color: `Hsv(rgba("#FF0000"))`
/// - HSLA color: `Hsv(hsla(360.0, 1.0, 0.5, 1.0))`
pub fn Hsv(args: anytype) HSV {
    const ArgsType = @TypeOf(args);

    return switch (@typeInfo(ArgsType)) {
        .@"struct" => if (@typeInfo(ArgsType).@"struct".is_tuple) blk: {
            if (args.len != 4 and args.len != 3) {
                @compileError("Expected 3 or 4 arguments (h,s,v,[a]) for HSV color");
            }
            break :blk HSV{
                .h = math.clamp(args[0], 0.0, 360.0),
                .s = math.clamp(args[1], 0.0, 1.0),
                .v = math.clamp(args[2], 0.0, 1.0),
                .a = if (args.len == 4) math.clamp(args[3], 0.0, 1.0) else 1.0,
            };
        } else if (ArgsType == RGBA) {
            return args.toHsv();
        } else if (ArgsType == HSLA) {
            return args.toHsv();
        } else error.UnsupportedStructType,

        else => if (comptime true) {
            @compileError("Expected float tuple or color type, found " ++ @typeName(ArgsType));
        } else {
            return error.UnsupportedType;
        },
    };
}
