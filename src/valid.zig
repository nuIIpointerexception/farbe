/// Validates a string as a color string.
pub fn String(comptime str: []const u8) type {
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
            else => @compileError("Invalid hex character in color string: '" ++ c ++ "'"),
        }
    }
    return []const u8;
}

/// Helper function to check if a type is a string.
pub fn ZigStr(comptime T: type) bool {
    return @typeInfo(T) == .array and @typeInfo(T).array.child == u8;
}

/// Validates a tuple/array as HSLA values.
pub fn Hsla(comptime T: type) bool {
    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |struct_info| {
            if (!struct_info.is_tuple) return false;
            if (struct_info.fields.len < 3 or struct_info.fields.len > 4) return false;

            inline for (struct_info.fields) |field| {
                const field_type = field.type;
                if (@typeInfo(field_type) != .float and @typeInfo(field_type) != .ComptimeFloat) {
                    return false;
                }
            }
            return true;
        },
        .array => |array_info| {
            if (array_info.len < 3 or array_info.len > 4) return false;
            return @typeInfo(array_info.child) == .float or
                @typeInfo(array_info.child) == .comptime_float;
        },
        else => return false,
    }
}

/// Validates a hex value as a color value.
pub fn Hex(comptime val: u32) type {
    if (val > 0xFFFFFFFF) {
        @compileError("Hex color value too large");
    }
    if (val > 0xFFFFFF and val > 0xFFFFFFFF) {
        @compileError("Invalid hex color format. Must be either RGB (6 digits) or RGBA (8 digits)");
    }
    return u32;
}

/// Validates a value as a component value.
pub fn Value(comptime T: type, comptime val: T) type {
    switch (@TypeOf(val)) {
        u8 => {
            return u8;
        },
        f32 => {
            if (val < 0.0 or val > 1.0) {
                @compileError("Component value must be between 0.0 and 1.0");
            }
            return f32;
        },
        else => @compileError("Invalid component type"),
    }
}
