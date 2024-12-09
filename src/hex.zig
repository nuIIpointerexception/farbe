const xdigit_lookup = [_]bool{
    // 0-7
    false, false, false, false, false, false, false, false,
    // 8-15
    false, false, false, false, false, false, false, false,
    // 16-23
    false, false, false, false, false, false, false, false,
    // 24-31
    false, false, false, false, false, false, false, false,
    // 32-39
    false, false, false, false, false, false, false, false,
    // 40-47
    false, false, false, false, false, false, false, false,
    // 48-55 ('0'-'7')
    true,  true,  true,  true,  true,  true,  true,  true,
    // 56-63 ('8'-'9')
    true,  true,  false, false, false, false, false, false,
    // 64-71 ('A'-'F')
    false, true,  true,  true,  true,  true,  true,  false,
    // 72-79
    false, false, false, false, false, false, false, false,
    // 80-87
    false, false, false, false, false, false, false, false,
    // 88-95
    false, false, false, false, false, false, false, false,
    // 96-103 ('a'-'f')
    false, true,  true,  true,  true,  true,  true,  false,
};

pub fn isXDigit(c: u8) bool {
    return if (c < xdigit_lookup.len) xdigit_lookup[c] else false;
}

const lookup = [_]u8{
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 0-7
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 8-15
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 16-23
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 24-31
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 32-39
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 40-47
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 48-55 ('0'-'7')
    0x08, 0x09, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 56-63 ('8'-'9')
    0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff, // 64-71 ('A'-'F')
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 72-79
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 80-87
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 88-95
    0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff, // 96-103 ('a'-'f')
};

pub fn toDigit(c: u8) u8 {
    return if (c < lookup.len) lookup[c] else 0xff;
}

pub fn parse(s: []const u8) !u8 {
    const high = toDigit(s[0]);
    const low = toDigit(s[1]);
    if (high == 0xff or low == 0xff) return error.InvalidHexDigit;
    return (high << 4) | low;
}
