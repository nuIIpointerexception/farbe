const std = @import("std");

/// Validates a string as a color string.
pub fn isHexStr(comptime str: []const u8) type {
    if (str.len == 0) {
        @compileError("Empty color string");
    }
    if (str[0] != '#') {
        @compileError("Color string must start with '#'");
    }
    if (str.len != 7 and str.len != 9) {
        @compileError("Color string must be either '#RRGGBB' or '#RRGGBBAA'");
    }
    for (str[1..]) |c| {
        switch (c) {
            '0'...'9', 'a'...'f', 'A'...'F' => {},
            else => {
                // Current version will fail - need to use comptimePrint
                @compileError("Invalid hex character in color string: '" ++
                    std.fmt.comptimePrint("{c}", .{c}) ++ "'");
            },
        }
    }
    return []const u8;
}

/// Helper function to check if a type is a string.
pub fn isStr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .array => |array_info| array_info.child == u8,
        .pointer => |ptr_info| switch (@typeInfo(ptr_info.child)) {
            .array => |array_info| array_info.child == u8,
            else => false,
        },
        else => false,
    };
}

/// Validates a tuple/array as HSLA values.
pub fn isHsla(comptime T: type) bool {
    const info = @typeInfo(T);
    return switch (info) {
        .@"struct" => |struct_info| {
            if (!struct_info.is_tuple) return false;
            if (struct_info.fields.len < 3 or struct_info.fields.len > 4) return false;

            // Check field types
            inline for (struct_info.fields) |field| {
                switch (@typeInfo(field.type)) {
                    .float, .comptime_float => continue,
                    .int, .comptime_int => {
                        // Allow integers that can be safely converted to float
                        if (@typeInfo(field.type).bits <= 32) continue;
                        return false;
                    },
                    else => return false,
                }
            }

            // Validate ranges at compile time if possible
            if (comptime std.meta.trait.isConstPtr(T)) {
                const values = struct_info.fields[0].default_value orelse return true;
                inline for (values) |v| {
                    switch (@TypeOf(v)) {
                        f32, f64 => if (v < 0.0 or v > 1.0) return false,
                        else => {},
                    }
                }
            }

            return true;
        },
        .array => |array_info| {
            if (array_info.len < 3 or array_info.len > 4) return false;
            return switch (@typeInfo(array_info.child)) {
                .float, .comptime_float => true,
                .int, .comptime_int => @typeInfo(array_info.child).bits <= 32,
                else => false,
            };
        },
        else => false,
    };
}

/// Validates a hex value as a color value.
pub fn isHex(comptime val: u32) void {
    if (val > 0xFFFFFFFF) {
        @compileError("Hex color value too large");
    }
    if (val > 0xFFFFFF and val < 0xFF000000) {
        @compileError("Invalid hex color format. Must be either RGB (6 digits) or RGBA (8 digits)");
    }
}

/// Validates a value as a component value.
pub fn isValue(comptime T: type, comptime val: anytype) void {
    _ = T; // autofix
    switch (@TypeOf(val)) {
        f32, f64, comptime_float => {
            if (val < 0.0 or val > 1.0) {
                @compileError(std.fmt.comptimePrint("Component value {d} must be between 0.0 and 1.0", .{val}));
            }
        },
        u8 => {
            if (val > 255) {
                @compileError(std.fmt.comptimePrint("Component value {d} must be between 0 and 255", .{val}));
            }
        },
        i32, i64, comptime_int => {
            if (val < 0 or val > 255) {
                @compileError(std.fmt.comptimePrint("Component value {d} must be between 0 and 255", .{val}));
            }
        },
        else => @compileError("Invalid component type: " ++ @typeName(@TypeOf(val))),
    }
}
