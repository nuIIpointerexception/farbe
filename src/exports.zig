const std = @import("std");

const farbe = @import("farbe");

export fn farbe_rgba_from_components(r: u8, g: u8, b: u8, a: u8) farbe.RGBA {
    return farbe.Rgba(.{ r, g, b, a }) catch unreachable;
}

export fn farbe_rgba_from_hex(hex: u32) farbe.RGBA {
    return farbe.Rgba(hex) catch unreachable;
}

export fn farbe_hsla(h: f32, s: f32, l: f32, a: f32) farbe.HSLA {
    return farbe.Hsla(h, s, l, a);
}

export fn farbe_rgba_from_hsla(h: f32, s: f32, l: f32, a: f32) farbe.RGBA {
    const hsla = farbe_hsla_create(h, s, l, a);
    return hsla.toRgba();
}

export fn farbe_rgba_blend(a: farbe.RGBA, b: farbe.RGBA) farbe.RGBA {
    return a.blend(b);
}

export fn farbe_rgba_to_hsla(color: farbe.RGBA) farbe.HSLA {
    return color.toHsla();
}

export fn farbe_rgba_to_u32(color: farbe.RGBA) u32 {
    return color.toU32();
}

export fn farbe_hsla_create(h: f32, s: f32, l: f32, a: f32) farbe.HSLA {
    if (!std.math.isFinite(h) or !std.math.isFinite(s) or
        !std.math.isFinite(l) or !std.math.isFinite(a))
    {
        return farbe.HSLA.init(0, 0, 0, 0);
    }
    return farbe.HSLA.init(h, s, l, a);
}

export fn farbe_hsla_from_rgba(color: farbe.RGBA) farbe.HSLA {
    return farbe.HSLA.fromRgba(color);
}

export fn farbe_hsla_blend(a: farbe.HSLA, b: farbe.HSLA) farbe.HSLA {
    return a.blend(b);
}

export fn farbe_hsla_grayscale(color: farbe.HSLA) farbe.HSLA {
    return color.grayscale();
}

export fn farbe_hsla_opacity(color: farbe.HSLA, factor: f32) farbe.HSLA {
    return color.opacity(factor);
}

export fn farbe_hsla_fade_out(color: *farbe.HSLA, factor: f32) void {
    color.fadeOut(factor);
}
