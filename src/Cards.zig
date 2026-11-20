ids: []const u8,
R: ev.Deck,

pub fn fromIds(comptime R: ev.Deck, ids: []const u8) Cards {
    if (@import("builtin").is_test) {
        var i: usize = 1;
        while (i < ids.len) : (i += 1)
            assert(ids[i] >> 2 < R.int());
    }
    return .{ .ids = ids, .R = R };
}

pub fn idsFromNames(comptime R: ev.Deck, hand: []const u8, ids: []u8) void {
    const N = @divExact(hand.len, 2);
    assert(hand.len == N * 2);
    const names: []const [2]u8 = @ptrCast(hand);
    for (ids, names) |*card, *name| {
        card.* = Card.fromName(R.int(), name);
    }
}

pub fn format(cs: Cards, w: *Io.Writer) !void {
    switch (cs.R) {
        .full => for (cs.ids) |*id| {
            try Card.Fmt.format(.{ .c = .{ .id = id.* } }, w);
        },
        .short => for (cs.ids) |*id| {
            try Card.FmtShort.format(.{ .c = .{ .id = id.* } }, w);
        },
    }
}

const FmtColor = struct {
    cards: Cards,
    pub fn format(f: Cards.FmtColor, w: *Io.Writer) !void {
        for (f.cards.ids) |*id| {
            try Card.FmtColor.format(.{ .R = f.cards.R.int(), .c = .{ .id = id.* } }, w);
        }
    }
};

pub fn fmtColor(cs: Cards) Cards.FmtColor {
    return .{ .cards = cs };
}

const Cards = @This();
const std = @import("std");
const Io = std.Io;
const Card = @import("Card.zig");
const ev = @import("evaluator.zig");
const assert = std.debug.assert;
