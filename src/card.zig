id: u7,

const std = @import("std");
const Self = @This();
pub fn init(id: u7) Self {
    return .{ .id = id };
}
pub fn initFromName(name: []const u8) !Self {
    std.debug.assert(name.len == 2);
    const rank = switch (name[0]) {
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
        else => return error.invalidRank,
    };
    const suit = switch (name[1]) {
        'C', 'c' => 0,
        'D', 'd' => 1,
        'H', 'h' => 2,
        'S', 's' => 3,
        else => return error.invalidSuit,
    };
    return Self{ .id = rank * 4 + suit };
}

pub fn toRankSuit(card: Self) [2]u8 {
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
    const st = card.id % 4;
    const suit: u8 = switch (st) {
        0 => 'c',
        1 => 'd',
        2 => 'h',
        3 => 's',
        else => '?',
    };
    return [2]u8{ rank, suit };
}

pub fn describe_cards(cards: []Self, buf: []u8) ![]u8 {
    std.debug.assert(cards.len * 2 <= buf.len);
    for (cards) |card, i| {
        std.mem.copy(u8, buf[i * 2 .. i * 2 + 2], &card.toRankSuit());
    }
    return buf[0 .. cards.len * 2];
}
