const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;
const expectApproxEqRel = std.testing.expectApproxEqRel;

const farbe = @import("farbe");
const Rgba = farbe.rgba;
const Hsla = farbe.hsla;
const Hsv = farbe.hsv;

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

test "hsv to rgba" {
    const red_hsv = Hsv(.{ 0.0, 1.0, 1.0 });
    const red_rgba = red_hsv.toRgba();
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.r)) / 255.0, 1.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.g)) / 255.0, 0.0, 1e-6);
    try expectApproxEqAbs(@as(f32, @floatFromInt(red_rgba.b)) / 255.0, 0.0, 1e-6);
    try expectEqual(255, red_rgba.a);
}

test "hsv blend" {
    const red = Hsv(.{ 0.0, 1.0, 1.0 });
    const blue = Hsv(.{ 240.0, 1.0, 1.0 });
    const purple = red.blend(blue);
    const expected = Hsv(.{ 300.0, 1.0, 1.0 });
    try expectApproxEqRel(expected.h, purple.h, 1e-6);
    try expectApproxEqRel(expected.s, purple.s, 1e-6);
    try expectApproxEqRel(expected.v, purple.v, 1e-6);
    try expectEqual(expected.a, purple.a);
}

// test "hsv grayscale" {
//     var red = Hsv(.{ 0.0, 1.0, 1.0 });
//     const gray = red.grayscale();
//     try expectEqual(0.0, gray.h);
//     try expectEqual(0.0, gray.s);
//     try expectEqual(0.5, gray.v);
//     try expectEqual(1.0, gray.a);
// }

test "hsv fadeout" {
    var red = Hsv(.{ 0.0, 1.0, 1.0 });
    red.fadeOut(0.5);
    try expectEqual(0.5, red.a);
}

test "hsv opacity" {
    const red = Hsv(.{ 0.0, 1.0, 1.0 });
    const faded = red.opacity(0.5);
    try expectEqual(0.5, faded.a);
}
