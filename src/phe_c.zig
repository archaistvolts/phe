pub extern fn evaluate_5cards(c_int, c_int, c_int, c_int, c_int) c_int;
pub extern fn evaluate_7cards(c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
pub extern fn evaluate_omaha_cards(c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;

pub fn evaluateNCards(N: comptime_int, R: usize, cs: [N]u8) u32 {
    _ = R;
    return @intCast(switch (N) {
        5 => evaluate_5cards(cs[0], cs[1], cs[2], cs[3], cs[4]),
        7 => evaluate_7cards(cs[0], cs[1], cs[2], cs[3], cs[4], cs[5], cs[6]),
        else => unreachable,
    });
}

const std = @import("std");
