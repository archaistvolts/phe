id: u8,

const std = @import("std");
const Card = @This();
pub fn init(id: u8) Card {
    return .{ .id = id };
}

pub fn nameToSuit(c: u8) u2 {
    return switch (c) {
        'C', 'c' => 0,
        'D', 'd' => 1,
        'H', 'h' => 2,
        'S', 's' => 3,
        else => @panic("invalid suit"),
    };
}

pub fn suitToName(c: u2) u8 {
    return switch (c) {
        0 => 'c',
        1 => 'd',
        2 => 'h',
        3 => 's',
    };
}

/// '2' => 0, 'A' => 12
pub fn nameToRank(name: u8) u8 {
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
        else => invalid_rank,
    };
}

pub fn initFromName(name: []const u8) u8 {
    std.debug.assert(name.len == 2);
    // std.debug.warn("name {}\n", .{name});
    const rank = nameToRank(name[0]);
    const suit = nameToSuit(name[1]);
    return rank * 4 + suit;
}

pub fn nameToRankSd(name: u8) u8 {
    return switch (name) {
        '6' => 0,
        '7' => 1,
        '8' => 2,
        '9' => 3,
        'T', 't' => 4,
        'J', 'j' => 5,
        'Q', 'q' => 6,
        'K', 'k' => 7,
        'A', 'a' => 8,
        else => invalid_rank,
    };
}

pub fn initFromNameSd(name: []const u8) u8 {
    std.debug.assert(name.len == 2);
    const rank: u8 = nameToRankSd(name[0]);
    const suit = nameToSuit(name[1]);
    return rank * 4 + suit;
}

pub fn toRankSuit(card: u8) [2]u8 {
    const rk = card >> 2;
    std.debug.assert(rk < 13);
    const rank: u8 = switch (rk) {
        0...7 => '2' + rk,
        8 => 'T',
        9 => 'J',
        10 => 'Q',
        11 => 'K',
        12 => 'A',
        else => '?',
    };
    const suit = suitToName(@as(u2, @intCast(card & 0b11)));
    return [2]u8{ rank, suit };
}

pub fn toRankSuitSd(card: u8) [2]u8 {
    const rk = card >> 2;
    std.debug.assert(rk < 9);
    const rank: u8 = switch (rk) {
        0...3 => '6' + rk,
        4 => 'T',
        5 => 'J',
        6 => 'Q',
        7 => 'K',
        8 => 'A',
        else => '?',
    };
    const suit = suitToName(@as(u2, @intCast(card % 4)));
    return [2]u8{ rank, suit };
}

pub fn cardsToString(cards: []const u8, buf: []u8) []u8 {
    std.debug.assert(cards.len * 2 <= buf.len);
    for (cards, 0..) |card, i| {
        @memcpy(buf[i * 2 .. i * 2 + 2], &Card.toRankSuit(card));
    }
    return buf[0 .. cards.len * 2];
}

pub fn cardsToStringSd(cards: []const u8, buf: []u8) []u8 {
    std.debug.assert(cards.len * 2 <= buf.len);
    for (cards, 0..) |card, i| {
        @memcpy(buf[i * 2 .. i * 2 + 2], &Card.toRankSuitSd(card));
    }
    return buf[0 .. cards.len * 2];
}

pub fn cardsFromString(comptime len: u8, string: []const u8) [len]u8 {
    std.debug.assert(string.len == len * 2);
    var cards: [len]u8 = undefined;
    for (&cards, 0..) |*card, i| card.* = initFromName(string[i * 2 .. i * 2 + 2]);
    return cards;
}

pub fn cardsFromStringSd(comptime len: u8, string: []const u8) [len]u8 {
    var cards: [len]u8 = undefined;
    for (&cards, 0..) |*card, i| card.* = initFromNameSd(string[i * 2 .. i * 2 + 2]);
    return cards;
}

const testing = std.testing;

test "round trip ids to string" {
    const util = @import("util.zig");

    const cb = struct {
        fn func(ids: [5]u8, ctx: anytype) !bool {
            _ = ctx;
            var buf: [10]u8 = undefined;
            const hand = cardsToString(ids[0..5], &buf);
            const cards2 = cardsFromString(5, hand);
            var buf2: [10]u8 = undefined;
            const hand2 = cardsToString(cards2[0..5], &buf2);
            try testing.expectEqualSlices(u8, hand, hand2);
            var ids2: [5]u8 = undefined;
            for (cards2, 0..) |c, i| ids2[i] = c;
            try testing.expectEqualSlices(u8, ids[0..], ids2[0..]);
            return true;
        }
    }.func;
    try util.comb5Cb(0, 13, cb, {});
}

/// 'A' => '2', 'Q' => 'K'
pub fn toAlo(card: u8) u8 {
    return (rankToAlo(card >> 2) << 2) | (card & 0b11);
}

test "toAlo" {
    try testing.expectEqual(Card.initFromName("2c"), Card.toAlo(Card.initFromName("Ac")));
    try testing.expectEqual(Card.initFromName("2s"), Card.toAlo(Card.initFromName("As")));
    try testing.expectEqual(Card.initFromName("3c"), Card.toAlo(Card.initFromName("2c")));
    try testing.expectEqual(Card.initFromName("4c"), Card.toAlo(Card.initFromName("3c")));
    try testing.expectEqual(Card.initFromName("5c"), Card.toAlo(Card.initFromName("4c")));
    try testing.expectEqual(Card.initFromName("6c"), Card.toAlo(Card.initFromName("5c")));
    try testing.expectEqual(Card.initFromName("7c"), Card.toAlo(Card.initFromName("6c")));
    try testing.expectEqual(Card.initFromName("8c"), Card.toAlo(Card.initFromName("7c")));
    try testing.expectEqual(Card.initFromName("9c"), Card.toAlo(Card.initFromName("8c")));
    try testing.expectEqual(Card.initFromName("Tc"), Card.toAlo(Card.initFromName("9c")));
    try testing.expectEqual(Card.initFromName("Jc"), Card.toAlo(Card.initFromName("Tc")));
    try testing.expectEqual(Card.initFromName("Qc"), Card.toAlo(Card.initFromName("Jc")));
    try testing.expectEqual(Card.initFromName("Kc"), Card.toAlo(Card.initFromName("Qc")));
    try testing.expectEqual(Card.initFromName("Ac"), Card.toAlo(Card.initFromName("Kc")));
    try testing.expectEqual(Card.initFromName("As"), Card.toAlo(Card.initFromName("Ks")));
}

const invalid_rank = std.math.maxInt(u8);
pub fn rankToAlo(rank: u8) u8 {
    // std.debug.warn("rankToAlo {}\n", .{rank});
    std.debug.assert(rank < 13);
    return (rank + 1) % 13;
}

pub fn cardsToAlo(comptime len: u8, cards: []const u8) [len]u8 {
    std.debug.assert(cards.len == len);
    var result: [len]u8 = undefined;
    comptime var i: u8 = 0;
    inline while (i < len) : (i += 1) result[i] = toAlo(cards[i]);
    return result;
}
