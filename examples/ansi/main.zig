const std = @import("std");

const Rgba = @import("farbe").Rgba;

pub fn main() !void {
    const stdout = std.io.getStdOut();
    var buf = std.io.bufferedWriter(stdout.writer());
    const writer = buf.writer();
    const is_windows = @import("builtin").os.tag == .windows;

    if (!stdout.isTty()) return;

    if (is_windows or try supportsColorPosix(stdout)) {
        const red = try Rgba(.{ 255, 0, 0, 255 });
        try writer.print("\x1b[38;2;{};{};{}m", .{ red.r, red.g, red.b });
        try writer.print("Hello, Red!\n", .{});
        try writer.print("\x1b[0m", .{});
    } else {
        try writer.print("Not, Supported!\n", .{});
    }

    try buf.flush();
}

fn supportsColorPosix(file: std.fs.File) !bool {
    const fd = file.getHandle();
    if (std.os.isatty(fd) != 1 or std.process.env.get("NO_COLOR") != null) return false;
    if (std.process.env.get("TERM")) |term| return !std.mem.eql(u8, term, "dumb");
    return false;
}
