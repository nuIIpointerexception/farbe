const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;
const expectApproxEqRel = std.testing.expectApproxEqRel;

const farbe = @import("farbe");
const Rgba = farbe.rgba;
const RGBA = farbe.RGBA;
const Hsla = farbe.hsla;
const Hsv = farbe.hsv;

test "rgba init" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    try expectEqual(255, red.r);
    try expectEqual(0, red.g);
    try expectEqual(0, red.b);
    try expectEqual(255, red.a);

    const clamped = try Rgba(.{ 300, -10, 1000, -5 });
    try expectEqual(255, clamped.r);
    try expectEqual(0, clamped.g);
    try expectEqual(255, clamped.b);
    try expectEqual(0, clamped.a);
}

test "rgba from hex" {
    const red1 = try Rgba(0xFF0000FF);
    const red2 = try Rgba(0xFF0000);
    const semi = try Rgba(0xFF0000A0);

    try expectEqual(255, red1.r);
    try expectEqual(255, red1.a);
    try expectEqual(255, red2.a);
    try expectEqual(160, semi.a);
}

test "rgba blend operations" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const blue = try Rgba(.{ 0, 0, 255, 255 });
    const trans = try Rgba(.{ 0, 255, 0, 128 });

    const purple = red.blend(blue);
    try expectEqual(127, purple.r);
    try expectEqual(0, purple.g);
    try expectEqual(127, purple.b);
    try expectEqual(255, purple.a);

    const blended = red.blend(trans);
    try expectEqual(@as(u8, 128), blended.r);
    try expectEqual(@as(u8, 128), blended.g);
}

test "rgba blend multiple simd" {
    const colors1 = [_]RGBA{
        try Rgba(.{ 255, 0, 0, 255 }),
        try Rgba(.{ 0, 255, 0, 255 }),
        try Rgba(.{ 0, 0, 255, 255 }),
        try Rgba(.{ 255, 255, 255, 255 }),
    };
    const colors2 = [_]RGBA{
        try Rgba(.{ 0, 0, 255, 255 }),
        try Rgba(.{ 255, 0, 0, 255 }),
        try Rgba(.{ 0, 255, 0, 255 }),
        try Rgba(.{ 0, 0, 0, 255 }),
    };

    const results = RGBA.blendMultiple(4, colors1, colors2);
    try expectEqual(@as(u8, 127), results[0].r);
    try expectEqual(@as(u8, 127), results[1].g);
    try expectEqual(@as(u8, 127), results[2].b);
    try expectEqual(@as(u8, 127), results[3].r);
}

test "rgba conversions" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    try expectEqual(0xFF0000FF, red.toU32());

    const hex_red = try Rgba("#FF0000FF");
    try expectEqual(red.r, hex_red.r);

    const short_hex = try Rgba("#FF0000");
    try expectEqual(@as(u8, 255), short_hex.a);
}

test "rgba string parsing errors" {
    try expectError(error.InvalidFormat, Rgba(""));
    try expectError(error.InvalidFormat, Rgba("#"));
    try expectError(error.InvalidFormat, Rgba("#12"));
    try expectError(error.InvalidFormat, Rgba("#1234567"));
    try expectError(error.InvalidHexDigit, Rgba("#GGGGGG"));
}

test "rgba grayscale" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const gray = red.grayscale();
    const expected = @as(u8, @intFromFloat(255 * 0.2126));
    try expectEqual(expected, gray.r);
    try expectEqual(expected, gray.g);
    try expectEqual(expected, gray.b);
    try expectEqual(red.a, gray.a);
}

test "rgba opacity operations" {
    var red = try Rgba(.{ 255, 0, 0, 255 });
    red.fadeOut(0.5);
    try expectEqual(127, red.a);

    const faded = red.opacity(0.5);
    try expectEqual(63, faded.a);

    const edge_cases = [_]f32{ 0.0, 1.0, -0.5, 1.5 };
    for (edge_cases) |factor| {
        const result = red.opacity(factor);
        const expected: u8 = if (factor <= 0.0)
            0
        else if (factor >= 1.0)
            red.a
        else
            @intFromFloat(@as(f32, @floatFromInt(red.a)) * factor);
        try expectEqual(expected, result.a);
    }
}

test "rgba color space conversions" {
    const colors = [_]RGBA{
        try Rgba(.{ 255, 0, 0, 255 }), // red
        try Rgba(.{ 0, 255, 0, 255 }), // green
        try Rgba(.{ 0, 0, 255, 255 }), // blue
        try Rgba(.{ 128, 128, 128, 255 }), // gray
    };

    for (colors) |color| {
        const hsla = color.toHsla();
        const back_rgba_hsla = try Rgba(hsla);

        const orig_norm = @as(f32, @floatFromInt(color.r)) / 255.0;
        const back_norm = @as(f32, @floatFromInt(back_rgba_hsla.r)) / 255.0;
        try expectApproxEqRel(orig_norm, back_norm, 1e-2);
    }
}
test "rgba validation - compiler errors" {
    try std.testing.expectError(error.InvalidHexDigit, Rgba("#GG0000"));
    try std.testing.expectError(error.InvalidFormat, Rgba("#12345"));
    try std.testing.expectError(error.InvalidFormat, Rgba("#1234567"));
    try std.testing.expectError(error.InvalidFormat, Rgba(""));
    try std.testing.expectError(error.InvalidFormat, Rgba("FF0000"));
}

test "rgba validation - runtime bounds" {
    const max = try Rgba(.{ 255, 255, 255, 255 });
    try expectEqual(@as(u32, 0xFFFFFFFF), max.toU32());

    const min = try Rgba(.{ 0, 0, 0, 0 });
    try expectEqual(@as(u32, 0x00000000), min.toU32());

    const overflow = try Rgba(.{ 256, 300, 1000, 500 });
    try expectEqual(@as(u8, 255), overflow.r);
    try expectEqual(@as(u8, 255), overflow.g);
    try expectEqual(@as(u8, 255), overflow.b);
    try expectEqual(@as(u8, 255), overflow.a);

    const underflow = try Rgba(.{ -1, -100, -255, -500 });
    try expectEqual(@as(u8, 0), underflow.r);
    try expectEqual(@as(u8, 0), underflow.g);
    try expectEqual(@as(u8, 0), underflow.b);
    try expectEqual(@as(u8, 0), underflow.a);
}

test "rgba validation - hex parsing" {
    const rgb = try Rgba("#FF0000");
    try expectEqual(@as(u8, 255), rgb.r);
    try expectEqual(@as(u8, 0), rgb.g);
    try expectEqual(@as(u8, 0), rgb.b);
    try expectEqual(@as(u8, 255), rgb.a);

    const rgba = try Rgba("#FF0000FF");
    try expectEqual(@as(u8, 255), rgba.r);
    try expectEqual(@as(u8, 0), rgba.g);
    try expectEqual(@as(u8, 0), rgba.b);
    try expectEqual(@as(u8, 255), rgba.a);

    const lower = try Rgba("#ff0000");
    try expectEqual(@as(u8, 255), lower.r);

    const mixed = try Rgba("#Ff00fF");
    try expectEqual(@as(u8, 255), mixed.r);
    try expectEqual(@as(u8, 255), mixed.b);

    try expectError(error.InvalidFormat, Rgba("#"));
    try expectError(error.InvalidFormat, Rgba("#12"));
    try expectError(error.InvalidFormat, Rgba("#1234567"));
    try expectError(error.InvalidHexDigit, Rgba("#GGGGGG"));
    try expectError(error.InvalidHexDigit, Rgba("#/00000"));
    try expectError(error.InvalidHexDigit, Rgba("#@FFFFF"));
}

test "rgba validation - color space boundaries" {
    const colors = [_]struct { rgba: RGBA, desc: []const u8 }{
        .{ .rgba = try Rgba(.{ 0, 0, 0, 255 }), .desc = "black" },
        .{ .rgba = try Rgba(.{ 255, 255, 255, 255 }), .desc = "white" },
        .{ .rgba = try Rgba(.{ 255, 0, 0, 255 }), .desc = "red" },
        .{ .rgba = try Rgba(.{ 0, 255, 0, 255 }), .desc = "green" },
        .{ .rgba = try Rgba(.{ 0, 0, 255, 255 }), .desc = "blue" },
        .{ .rgba = try Rgba(.{ 128, 128, 128, 255 }), .desc = "gray" },
    };

    const tolerance: i32 = 2;
    for (colors) |color| {
        const hsv = color.rgba.toHsv();
        const back_from_hsv = try Rgba(hsv);
        try expectEqual(color.rgba.a, back_from_hsv.a);

        if (color.rgba.r == color.rgba.g and color.rgba.g == color.rgba.b) {
            try expectEqual(color.rgba.r, back_from_hsv.r);
            try expectEqual(color.rgba.g, back_from_hsv.g);
            try expectEqual(color.rgba.b, back_from_hsv.b);
        } else {
            const r_diff = @abs(@as(i32, color.rgba.r) - @as(i32, back_from_hsv.r));
            const g_diff = @abs(@as(i32, color.rgba.g) - @as(i32, back_from_hsv.g));
            const b_diff = @abs(@as(i32, color.rgba.b) - @as(i32, back_from_hsv.b));
            try std.testing.expect(r_diff <= tolerance);
            try std.testing.expect(g_diff <= tolerance);
            try std.testing.expect(b_diff <= tolerance);
        }

        const hsla = color.rgba.toHsla();
        const back_from_hsla = try Rgba(hsla);
        try expectEqual(color.rgba.a, back_from_hsla.a);

        if (color.rgba.r == color.rgba.g and color.rgba.g == color.rgba.b) {
            try expectEqual(color.rgba.r, back_from_hsla.r);
            try expectEqual(color.rgba.g, back_from_hsla.g);
            try expectEqual(color.rgba.b, back_from_hsla.b);
        } else {
            const r_diff = @abs(@as(i32, color.rgba.r) - @as(i32, back_from_hsla.r));
            const g_diff = @abs(@as(i32, color.rgba.g) - @as(i32, back_from_hsla.g));
            const b_diff = @abs(@as(i32, color.rgba.b) - @as(i32, back_from_hsla.b));
            try std.testing.expect(r_diff <= tolerance);
            try std.testing.expect(g_diff <= tolerance);
            try std.testing.expect(b_diff <= tolerance);
        }
    }
}

test "rgba validation - alpha blending edge cases" {
    const transparent = try Rgba(.{ 0, 0, 0, 0 });
    const full = try Rgba(.{ 255, 255, 255, 255 });
    const semi = try Rgba(.{ 128, 128, 128, 128 });

    const blend1 = transparent.blend(full);
    try expectEqual(blend1.toU32(), full.toU32());

    const blend2 = full.blend(transparent);
    try expectEqual(blend2.toU32(), full.toU32());

    const blend3 = semi.blend(semi);
    try expectEqual(@as(u8, 128), blend3.r);
    try expectEqual(@as(u8, 192), blend3.a);
}
