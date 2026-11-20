id: u8,

pub fn suitName(c: u8, case: enum { upper, lower }) u8 {
    return ([_][]const u8{ "cdhs", "CDHS" })[@intFromBool(case == .upper)][c & 0b11];
}

pub fn rankName(R: comptime_int, c: u8, case: enum { upper, lower }) u8 {
    const r = c >> 2;

    return (switch (R) {
        13 => ([_][]const u8{ "23456789tjqka", "23456789TJQKA" })[@intFromBool(case == .upper)][r],
        9 => ([_][]const u8{ "6789tjqka", "6789TJKQA" })[@intFromBool(case == .upper)][r],
        else => unreachable,
    });
}

pub const Fmt = struct {
    c: Card,

    pub fn format(f: Fmt, w: *Io.Writer) !void {
        try w.print("{c}{c}", .{ rankName(13, f.c.id, .upper), suitName(f.c.id, .lower) });
    }
};

pub const FmtShort = struct {
    c: Card,

    pub fn format(f: Fmt, w: *Io.Writer) !void {
        try w.print("{c}{c}", .{ rankName(9, f.c.id, .upper), suitName(f.c.id, .lower) });
    }
};

pub fn suitVtEscape(c: u8) []const u8 {
    return ([4][]const u8{
        "\x1b[38;2;0;230;0m", //        c - green
        "\x1b[38;2;120;120;255m", //    d - blue
        "\x1b[31m", //                  h - red
        "\x1b[38;2;120;120;120m", //    s - bright black
    })[@as(u2, @truncate(c))];
}

/// ranks only colored with VT escapes
pub const FmtColor = struct {
    c: Card,
    R: u8,

    pub fn format(x: FmtColor, w: *Io.Writer) !void {
        const reset = "\x1b[0m";
        try w.print("{s}{c}{s}", .{
            suitVtEscape(x.c.id),
            switch (x.R) {
                13 => rankName(13, x.c.id, .upper),
                9 => rankName(9, x.c.id, .upper),
                else => unreachable,
            },
            reset,
        });
    }
};

/// '2' => 0, 'A' => 12
pub fn nameRank(name: u8) u8 {
    return switch (name) {
        '2' => 0,
        '3' => 1,
        '4' => 2,
        '5' => 3,
        '6' => 4,
        '7' => 5,
        '8' => 6,
        '9' => 7,
        'T', 't' => 8,
        'J', 'j' => 9,
        'Q', 'q' => 10,
        'K', 'k' => 11,
        'A', 'a' => 12,
        else => unreachable,
    };
}

pub fn nameSuit(c: u8) u2 {
    return switch (c) {
        'C', 'c' => 0,
        'D', 'd' => 1,
        'H', 'h' => 2,
        'S', 's' => 3,
        else => unreachable,
    };
}

pub fn fromName(comptime R: comptime_int, name: *const [2]u8) u8 {
    assert(name.len == 2);
    assert(R != 9 or name[0] >= '6');
    const rank = nameRank(name[0]) - if (R == 9) 4 else 0;
    return rank << 2 | nameSuit(name[1]);
}

const Card = @This();
const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

// const testing = std.testing;
//
// test "round trip ids to string" {
//     const util = @import("util.zig");
//
//     const cb = struct {
//         fn func(ids: [5]u8, ctx: anytype) !bool {
//             _ = ctx;
//             var cards = cardsFromIds(5, &ids);
//             var buf: [10]u8 = undefined;
//             const hand = cardsToString(cards[0..5], &buf);
//             const cards2 = cardsFromString(5, hand);
//             var buf2: [10]u8 = undefined;
//             const hand2 = cardsToString(cards2[0..5], &buf2);
//             try testing.expectEqualSlices(u8, hand, hand2);
//             var ids2: [5]u8 = undefined;
//             for (cards2, 0..) |c, i| ids2[i] = c.id;
//             try testing.expectEqualSlices(u8, ids[0..], ids2[0..]);
//             return true;
//         }
//     }.func;
//     try util.comb5Cb(0, 13, cb, {});
// }
//
// test "toAlo" {
//     try testing.expectEqual(Card.initFromName("2c"), Card.toAlo(Card.initFromName("Ac")));
//     try testing.expectEqual(Card.initFromName("2s"), Card.toAlo(Card.initFromName("As")));
//     try testing.expectEqual(Card.initFromName("3c"), Card.toAlo(Card.initFromName("2c")));
//     try testing.expectEqual(Card.initFromName("4c"), Card.toAlo(Card.initFromName("3c")));
//     try testing.expectEqual(Card.initFromName("5c"), Card.toAlo(Card.initFromName("4c")));
//     try testing.expectEqual(Card.initFromName("6c"), Card.toAlo(Card.initFromName("5c")));
//     try testing.expectEqual(Card.initFromName("7c"), Card.toAlo(Card.initFromName("6c")));
//     try testing.expectEqual(Card.initFromName("8c"), Card.toAlo(Card.initFromName("7c")));
//     try testing.expectEqual(Card.initFromName("9c"), Card.toAlo(Card.initFromName("8c")));
//     try testing.expectEqual(Card.initFromName("Tc"), Card.toAlo(Card.initFromName("9c")));
//     try testing.expectEqual(Card.initFromName("Jc"), Card.toAlo(Card.initFromName("Tc")));
//     try testing.expectEqual(Card.initFromName("Qc"), Card.toAlo(Card.initFromName("Jc")));
//     try testing.expectEqual(Card.initFromName("Kc"), Card.toAlo(Card.initFromName("Qc")));
//     try testing.expectEqual(Card.initFromName("Ac"), Card.toAlo(Card.initFromName("Kc")));
//     try testing.expectEqual(Card.initFromName("As"), Card.toAlo(Card.initFromName("Ks")));
// }
