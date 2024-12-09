const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;
const expectApproxEqRel = std.testing.expectApproxEqRel;

const farbe = @import("farbe");
const Rgba = farbe.Rgba;
const Hsla = farbe.Hsla;
const Hsv = farbe.Hsv;

test "rgba init" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    try expectEqual(255, red.r);
    try expectEqual(0, red.g);
    try expectEqual(0, red.b);
    try expectEqual(255, red.a);
}

test "rgba" {
    const red = try Rgba(0xFF0000FF);
    try expectEqual(255, red.r);
    try expectEqual(0, red.g);
    try expectEqual(0, red.b);
    try expectEqual(255, red.a);
}

test "rgba blend" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const blue = try Rgba(.{ 0, 0, 255, 255 });
    const purple = red.blend(blue);
    try expectEqual(127, purple.r);
    try expectEqual(0, purple.g);
    try expectEqual(127, purple.b);
    try expectEqual(255, purple.a);
}

test "rgba to u32" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const red_u32 = red.toU32();
    try expectEqual(0xFF0000FF, red_u32);
}

test "rgba from str" {
    const red = try Rgba("#FF0000FF");
    try expectEqual(255, red.r);
    try expectEqual(0, red.g);
    try expectEqual(0, red.b);
    try expectEqual(255, red.a);

    const opaque_blue = try Rgba("#0000FFCC");
    try expectEqual(0, opaque_blue.r);
    try expectEqual(0, opaque_blue.g);
    try expectEqual(255, opaque_blue.b);
    try expectEqual(204, opaque_blue.a);
}

test "comptime rgba from str" {
    const red = try Rgba("#FF0000");
    try expectEqual(255, red.r);
    try expectEqual(0, red.g);
    try expectEqual(0, red.b);
    try expectEqual(255, red.a);
}

test "rgba from str error" {
    try expectError(error.InvalidFormat, Rgba("G00"));
    try expectError(error.InvalidFormat, Rgba("#0G0"));
    try expectError(error.InvalidHexDigit, Rgba("#0000G0"));
    try expectError(error.InvalidHexDigit, Rgba("#0000000G"));
}

test "rgba from hsla" {
    const red = try Rgba(Hsla(0.0, 1.0, 0.5, 1.0));
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.r)) / 255.0, 1.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.g)) / 255.0, 0.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.b)) / 255.0, 0.0, 1e-6);
    try expectEqual(255, red.a);
}

test "rgba from hsv" {
    const red = try Rgba(Hsv(.{ 0.0, 1.0, 1.0 }));
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.r)) / 255.0, 1.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.g)) / 255.0, 0.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red.b)) / 255.0, 0.0, 1e-6);
    try expectEqual(255, red.a);
}

// test "rgba grayscale" {
//     var red = try Rgba(.{ 255, 0, 0, 255 });
//     const gray = red.grayscale();
//     try expectEqual(127, gray.r);
//     try expectEqual(127, gray.g);
//     try expectEqual(127, gray.b);
//     try expectEqual(255, gray.a);
// }

test "rgba fadeout" {
    var red = try Rgba(.{ 255, 0, 0, 255 });
    red.fadeOut(0.5);
    try expectEqual(127, red.a);
}

test "rgba opacity" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const faded = red.opacity(0.5);
    try expectEqual(127, faded.a);
}

test "rgba to hsla" {
    var red = try Rgba(.{ 255, 0, 0, 255 });
    const red_hsla = red.toHsla();
    try expectApproxEqAbs(0.0, red_hsla.h, 1e-6);
    try expectEqual(1.0, red_hsla.s);
    try expectEqual(0.5, red_hsla.l);
    try expectEqual(1.0, red_hsla.a);
}

test "rgba to hsv" {
    const red = try Rgba(.{ 255, 0, 0, 255 });
    const red_hsv = red.toHsv();
    try expectApproxEqAbs(0.0, red_hsv.h, 1e-6);
    try expectEqual(1.0, red_hsv.s);
    try expectEqual(1.0, red_hsv.v);
    try expectEqual(1.0, red_hsv.a);
}
