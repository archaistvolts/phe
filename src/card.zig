id: u6,

const std = @import("std");
const Card = @This();
pub fn init(id: u6) Card {
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

pub fn initFromName(name: []const u8) Card {
    std.debug.assert(name.len == 2);
    // std.debug.warn("name {}\n", .{name});
    const rank: u6 = switch (name[0]) {
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
        else => @panic("invalid rank"),
    };
    const suit = nameToSuit(name[1]);
    return Card{ .id = rank * 4 + suit };
}

pub fn initFromNameSd(name: []const u8) Card {
    std.debug.assert(name.len == 2);
    const rank: u6 = switch (name[0]) {
        '6' => 0,
        '7' => 1,
        '8' => 2,
        '9' => 3,
        'T', 't' => 4,
        'J', 'j' => 5,
        'Q', 'q' => 6,
        'K', 'k' => 7,
        'A', 'a' => 8,
        else => @panic("invalid rank"),
    };
    const suit = nameToSuit(name[1]);
    return Card{ .id = rank * 4 + suit };
}

pub fn toRankSuit(card: Card) [2]u8 {
    const rk = card.id / 4;
    const rank: u8 = switch (rk) {
        0...7 => '2' + rk,
        8 => 'T',
        9 => 'J',
        10 => 'Q',
        11 => 'K',
        12 => 'A',
        else => '?',
    };
    const suit = suitToName(@intCast(u2, card.id % 4));
    return [2]u8{ rank, suit };
}

pub fn toRankSuitSd(card: Card) [2]u8 {
    const rk = card.id / 4;
    const rank: u8 = switch (rk) {
        0...3 => '6' + rk,
        4 => 'T',
        5 => 'J',
        6 => 'Q',
        7 => 'K',
        8 => 'A',
        else => '?',
    };
    const st = card.id % 4;
    const suit = suitToName(@intCast(u2, card.id % 4));
    return [2]u8{ rank, suit };
}

pub fn cardsToString(cards: []const Card, buf: []u8) []u8 {
    std.debug.assert(cards.len * 2 <= buf.len);
    for (cards) |card, i| {
        std.mem.copy(u8, buf[i * 2 .. i * 2 + 2], &card.toRankSuit());
    }
    return buf[0 .. cards.len * 2];
}

pub fn cardsToStringSd(cards: []const Card, buf: []u8) []u8 {
    std.debug.assert(cards.len * 2 <= buf.len);
    for (cards) |card, i| {
        std.mem.copy(u8, buf[i * 2 .. i * 2 + 2], &card.toRankSuitSd());
    }
    return buf[0 .. cards.len * 2];
}

pub fn cardsFromString(comptime len: u8, string: []const u8) [len]Card {
    var cards: [len]Card = undefined;
    for (cards) |*card, i| card.* = initFromName(string[i * 2 .. i * 2 + 2]);
    return cards;
}

pub fn cardsFromIds(comptime len: u8, ids: []const u6) [len]Card {
    std.debug.assert(ids.len == len);
    var result: [len]Card = undefined;
    for (result) |*id, i| id.* = init(ids[i]);
    return result;
}

pub fn cardsFromStringSd(comptime len: u8, string: []const u8) [len]Card {
    var cards: [len]Card = undefined;
    for (cards) |*card, i| card.* = initFromNameSd(string[i * 2 .. i * 2 + 2]);
    return cards;
}

test "round trip ids to string" {
    const util = @import("util.zig");
    var ch: std.event.Channel(?[5]u6) = undefined;
    ch.init(&[_]?[5]u6{});
    _ = async util.comb5(0, 52, &ch);
    while (ch.get()) |ids| {
        var cards = cardsFromIds(5, &ids);
        var buf: [10]u8 = undefined;
        const hand = cardsToString(cards[0..5], &buf);
        const cards2 = cardsFromString(5, hand);
        var buf2: [10]u8 = undefined;
        const hand2 = cardsToString(cards2[0..5], &buf2);
        std.testing.expectEqualSlices(u8, hand, hand2);
        var ids2: [5]u6 = undefined;
        for (cards2) |c, i| ids2[i] = c.id;
        std.testing.expectEqualSlices(u6, ids[0..], ids2[0..]);
    }
}
