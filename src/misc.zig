pub fn trace(src: std.builtin.SourceLocation, comptime fmt: []const u8, args: anytype) void {
    _ = src; // autofix
    if (@import("build-options").trace) {
        var buffer: [64]u8 = undefined;
        const stderr = std.debug.lockStderr(&buffer);
        defer std.debug.unlockStderr();
        var term = stderr.terminal();
        term.mode = .escape_codes;
        // term.writer.print("src/{s}:{}:{}: ", .{ src.file, src.line, src.column }) catch {};
        // term.setColor(.yellow) catch {};
        // term.writer.print("{s}", .{src.fn_name}) catch {};
        // term.setColor(.white) catch {};
        // term.writer.print(" : ", .{}) catch {};
        term.writer.print(fmt, args) catch {};
        // term.writer.print("\n", .{}) catch {};
    }
}

const std = @import("std");
