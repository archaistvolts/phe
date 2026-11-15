id: u8,

pub fn suitName(c: u8, case: enum { upper, lower }) u8 {
    return "cdhs"[@as(u2, @truncate(c))] ^
        @as(u8, @intFromBool(case == .upper)) * 32;
}

pub fn suitEscape(c: u8) []const u8 {
    return ([4][]const u8{
        "\x1b[38;2;0;230;0m", //        c - green
        "\x1b[38;2;120;120;255m", //    d - blue
        "\x1b[31m", //                  h - red
        "\x1b[38;2;120;120;120m", //    s - bright black
    })[@as(u2, @truncate(c))];
}

pub fn rankName(c: u8, case: enum { upper, lower }) u8 {
    const x = c >> 2;
    return "23456789tjqka"[x] ^
        @as(u8, @intFromBool(x > 7 and case == .upper)) * 32;
}

pub fn format(c: Card, w: *Io.Writer) !void {
    try w.print("{c}{c}", .{ rankName(c.id, .upper), suitName(c.id, .lower) });
}

const FmtColor = struct {
    c: Card,
    pub fn format(x: FmtColor, w: *Io.Writer) !void {
        const reset = "\x1b[0m";
        try w.print("{s}{c}{s}", .{
            suitEscape(x.c.id),
            rankName(x.c.id, .upper),
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

pub fn fromName(name: []const u8) u8 {
    std.debug.assert(name.len == 2);
    return (nameRank(name[0]) << 2) | nameSuit(name[1]);
}

pub const Cards = struct {
    ids: []const u8,

    pub fn fromIds(ids: []const u8) Cards {
        return .{ .ids = ids };
    }

    pub fn format(cs: Cards, w: *Io.Writer) !void {
        for (cs.ids) |*id| {
            // if (id != &cs.ids[0]) try w.writeByte(' ');
            try Card.format(.{ .id = id.* }, w);
        }
    }

    const FmtColor = struct {
        cards: Cards,
        pub fn format(f: Cards.FmtColor, w: *Io.Writer) !void {
            for (f.cards.ids) |*id| {
                try Card.FmtColor.format(.{ .c = .{ .id = id.* } }, w);
            }
        }
    };

    pub fn fmtColor(cs: Cards) Cards.FmtColor {
        return .{ .cards = cs };
    }
};

const Card = @This();
const std = @import("std");
const Io = std.Io;

// pub fn init(id: u8) Card {
//     return .{ .id = id };
// }
//
//
// pub fn suitToName(c: u2) u8 {
//     return switch (c) {
//         0 => 'c',
//         1 => 'd',
//         2 => 'h',
//         3 => 's',
//     };
// }
//
// pub fn nameToRankSd(name: u8) u8 {
//     return switch (name) {
//         '6' => 0,
//         '7' => 1,
//         '8' => 2,
//         '9' => 3,
//         'T', 't' => 4,
//         'J', 'j' => 5,
//         'Q', 'q' => 6,
//         'K', 'k' => 7,
//         'A', 'a' => 8,
//         else => invalid_rank,
//     };
// }
//
// pub fn initFromNameSd(name: []const u8) Card {
//     std.debug.assert(name.len == 2);
//     const rank: u8 = nameToRankSd(name[0]);
//     const suit = nameToSuit(name[1]);
//     return Card{ .id = rank * 4 + suit };
// }
//
// pub fn toRankSuit(card: Card) [2]u8 {
//     const rk = card.id >> 2;
//     std.debug.assert(rk < 13);
//     const rank: u8 = switch (rk) {
//         0...7 => '2' + rk,
//         8 => 'T',
//         9 => 'J',
//         10 => 'Q',
//         11 => 'K',
//         12 => 'A',
//         else => '?',
//     };
//     const suit = suitToName(@as(u2, @intCast(card.id & 0b11)));
//     return [2]u8{ rank, suit };
// }
//
// pub fn toRankSuitSd(card: Card) [2]u8 {
//     const rk = card.id >> 2;
//     std.debug.assert(rk < 9);
//     const rank: u8 = switch (rk) {
//         0...3 => '6' + rk,
//         4 => 'T',
//         5 => 'J',
//         6 => 'Q',
//         7 => 'K',
//         8 => 'A',
//         else => '?',
//     };
//     // const st = card.id & 0b11;
//     const suit = suitToName(@as(u2, @intCast(card.id % 4)));
//     return [2]u8{ rank, suit };
// }
//
// pub fn cardsToString(cards: []const Card, buf: []u8) []u8 {
//     std.debug.assert(cards.len * 2 <= buf.len);
//     for (cards, 0..) |card, i| {
//         @memcpy(buf[i * 2 .. i * 2 + 2], &card.toRankSuit());
//     }
//     return buf[0 .. cards.len * 2];
// }
//
// pub fn cardsToStringSd(cards: []const Card, buf: []u8) []u8 {
//     std.debug.assert(cards.len * 2 <= buf.len);
//     for (cards, 0..) |card, i| {
//         @memcpy(buf[i * 2 .. i * 2 + 2], &card.toRankSuitSd());
//     }
//     return buf[0 .. cards.len * 2];
// }
//
// pub fn cardsFromString(comptime len: u8, string: []const u8) [len]Card {
//     std.debug.assert(string.len == len * 2);
//     var cards: [len]Card = undefined;
//     for (&cards, 0..) |*card, i| card.* = initFromName(string[i * 2 .. i * 2 + 2]);
//     return cards;
// }
//
// pub fn cardsFromIds(comptime len: u8, ids: []const u8) [len]Card {
//     std.debug.assert(ids.len == len);
//     var result: [len]Card = undefined;
//     for (&result, 0..) |*id, i| id.* = init(ids[i]);
//     return result;
// }
//
// pub fn cardsFromStringSd(comptime len: u8, string: []const u8) [len]Card {
//     var cards: [len]Card = undefined;
//     for (&cards, 0..) |*card, i| card.* = initFromNameSd(string[i * 2 .. i * 2 + 2]);
//     return cards;
// }
//
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
// /// 'A' => '2', 'Q' => 'K'
// pub fn toAlo(card: Card) Card {
//     // std.debug.warn("toAlo {} {}\n", .{ card.id, card.id >> 2 });
//     return Card.init((rankToAlo(card.id >> 2) << 2) | (card.id & 0b11));
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
//
// const invalid_rank = std.math.maxInt(u8);
// pub fn rankToAlo(rank: u8) u8 {
//     // std.debug.warn("rankToAlo {}\n", .{rank});
//     std.debug.assert(rank < 13);
//     return (rank + 1) % 13;
// }
//
// pub fn cardsToAlo(comptime len: u8, cards: []const Card) [len]Card {
//     std.debug.assert(cards.len == len);
//     var result: [len]Card = undefined;
//     comptime var i: u8 = 0;
//     inline while (i < len) : (i += 1) result[i] = toAlo(cards[i]);
//     return result;
// }
