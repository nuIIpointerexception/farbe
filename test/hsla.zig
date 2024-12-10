const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;
const expectApproxEqRel = std.testing.expectApproxEqRel;

const farbe = @import("farbe");
const Hsla = farbe.hsla;

// const Rgba = farbe.rgba;
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
