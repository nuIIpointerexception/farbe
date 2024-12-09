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

test "rgba to hsla" {
    var red = try Rgba(.{ 255, 0, 0, 255 });
    const red_hsla = red.toHsla();
    try expectApproxEqAbs(0.0, red_hsla.h, 1e-6);
    try expectEqual(1.0, red_hsla.s);
    try expectEqual(0.5, red_hsla.l);
    try expectEqual(1.0, red_hsla.a);
}

test "hsla" {
    const red = Hsla(0.0, 1.0, 0.5, 1.0);
    try expectEqual(0.0, red.h);
    try expectEqual(1.0, red.s);
    try expectEqual(0.5, red.l);
    try expectEqual(1.0, red.a);
}

test "hsla init clamp" {
    const color = Hsla(396.0, 1.1, 1.1, 1.1);
    try expectEqual(360.0, color.h);
    try expectEqual(1.0, color.s);
    try expectEqual(1.0, color.l);
    try expectEqual(1.0, color.a);
}

test "hsla to rgba" {
    const red_hsla = Hsla(0.0, 1.0, 0.5, 1.0);
    const red_rgba = red_hsla.toRgba();
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.r)) / 255.0, 1.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.g)) / 255.0, 0.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.b)) / 255.0, 0.0, 1e-6);
    try expectEqual(255, red_rgba.a);
}

test "hsla blend" {
    const red = Hsla(0.0, 1.0, 0.5, 1.0);
    const blue = Hsla(240.0, 1.0, 0.5, 1.0);
    const purple = red.blend(blue);
    const expected = Hsla(300.0, 1.0, 0.5, 1.0);
    try expectApproxEqRel(expected.h, purple.h, 1e-6);
    try expectApproxEqRel(expected.s, purple.s, 1e-6);
    try expectApproxEqRel(expected.l, purple.l, 1e-6);
    try expectEqual(expected.a, purple.a);
}

test "hsla grayscale" {
    var red = Hsla(0.0, 1.0, 0.5, 1.0);
    const gray = red.grayscale();
    try expectEqual(0.0, gray.h);
    try expectEqual(0.0, gray.s);
    try expectEqual(0.5, gray.l);
    try expectEqual(1.0, gray.a);
}

test "hsla fadeout" {
    var red = Hsla(0.0, 1.0, 0.5, 1.0);
    red.fadeOut(0.5);
    try expectEqual(0.5, red.a);
}

test "hsla opacity" {
    const red = Hsla(0.0, 1.0, 0.5, 1.0);
    const faded = red.opacity(0.5);
    try expectEqual(0.5, faded.a);
}

// test "hsla from rgba" {
//     const red = try Rgba(255, 0, 0, 255);
//     const red_hsla = Hsla.fromRgba(red);
//     try expectApproxEqAbs(0.0, red_hsla.h, 1e-6);
//     try expectEqual(1.0, red_hsla.s);
//     try expectEqual(0.5, red_hsla.l);
//     try expectEqual(1.0, red_hsla.a);
// }

test "hsv init" {
    const red = Hsv(.{ 0.0, 1.0, 1.0 });
    try expectEqual(0.0, red.h);
    try expectEqual(1.0, red.s);
    try expectEqual(1.0, red.v);
    try expectEqual(1.0, red.a);
}

test "hsv init with alpha" {
    const red = Hsv(.{ 0.0, 1.0, 1.0, 0.5 });
    try expectEqual(0.0, red.h);
    try expectEqual(1.0, red.s);
    try expectEqual(1.0, red.v);
    try expectEqual(0.5, red.a);
}

test "hsv init clamp" {
    const color = Hsv(.{ 396.0, 1.1, 1.1, 1.1 });
    try expectEqual(360.0, color.h);
    try expectEqual(1.0, color.s);
    try expectEqual(1.0, color.v);
    try expectEqual(1.0, color.a);
}

test "hsv from rgba" {
    const rgba = try Rgba(.{ 255, 0, 0, 255 });
    const hsv = Hsv(rgba);
    try expectApproxEqAbs(0.0, hsv.h, 1e-6);
    try expectEqual(1.0, hsv.s);
    try expectEqual(1.0, hsv.v);
    try expectEqual(1.0, hsv.a);
}

test "hsv from hsla" {
    const hsla = Hsla(0.0, 1.0, 0.5, 1.0);
    const hsv = Hsv(hsla);
    try expectApproxEqAbs(0.0, hsv.h, 1e-6);
    try expectApproxEqAbs(1.0, hsv.s, 1e-6);
    try expectApproxEqAbs(1.0, hsv.v, 1e-6);
    try expectEqual(1.0, hsv.a);
}
