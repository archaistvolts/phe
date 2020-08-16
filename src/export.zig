const std = @import("std");
const warn = std.debug.warn;
const Card = @import("card.zig");
const Rank = @import("rank.zig");
const ev = @import("evaluator.zig");
pub export fn evaluate_5hand_w(hand: *c_void, hand_len: usize) c_short {
    const rank = ev.evaluate5Hand(@ptrCast([*]const u8, hand)[0..hand_len], 13);
    return @intCast(c_short, rank.value);
}

// pub export fn hash_quinary5_w(q: *c_void, num_ranks: u8, k: u8) c_ulong {
//     const p = @ptrCast([*]u8, q);
//     var ids: [52]u6 = undefined;
//     for (ids[0..num_ranks]) |*id, i| id.* = @intCast(u6, p[i]);
//     return @intCast(c_ulong, ev.hashQuinary(ids[0..num_ranks], num_ranks, k));
// }

pub export fn evaluate_5cards_w(a: u8, b: u8, c: u8, d: u8, e: u8) c_ushort {
    return ev.evaluate5Cards(
        Card.init(a),
        Card.init(b),
        Card.init(c),
        Card.init(d),
        Card.init(e),
        13,
    ).value;
}

pub export fn evaluate_7cards_w(a: u8, b: u8, c: u8, d: u8, e: u8, f: u8, g: u8) c_ushort {
    return ev.evaluate7Cards(
        Card.init(a),
        Card.init(b),
        Card.init(c),
        Card.init(d),
        Card.init(e),
        Card.init(f),
        Card.init(g),
        13,
    ).value;
}

pub export fn evaluate_7hand_w(hand: *c_void, hand_len: usize) c_short {
    const rank = ev.evaluate7Hand(@ptrCast([*]const u8, hand)[0..hand_len], 13);
    return @intCast(c_short, rank.value);
}

pub export fn cards_to_binary5_w(hand: [*]u8) u16 {
    // warn("cards_to_binary5_w hand {}\n", .{hand[0..14]});
    return ev.cardsToBinary(&Card.cardsFromString(5, hand[0..10]));
}

pub export fn cards_to_binary7_w(hand: [*]u8) u16 {
    // warn("cards_to_binary7_w hand {}\n", .{hand[0..14]});
    return ev.cardsToBinary(&Card.cardsFromString(7, hand[0..14]));
}
