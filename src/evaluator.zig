const std = @import("std");
const warn = std.debug.warn;
const Card = @import("card.zig");
const Rank = @import("rank.zig");
const _export = @import("export.zig");
comptime {
    _ = _export;
}
extern const flush: [8192]u16;
extern const noflush5: [6175]u16;
extern const noflush7: [49205]u16;
extern const choose: [53][10]u32;
extern const dp: [5][14][10]u32;
extern const suits: [4609]u8;
extern const noflush_omaha: [11238500]u16;
extern const flush_omaha: [4099095]u16;
extern const flush_sd5: [512]u16;
extern const noflush_sd5: [1278]u16;
extern const flush_sd7: [512]u16;
extern const noflush_sd7: [6030]u16;
extern const razz_hashtable5: [6175]u16;
// const razz_hashtable5: [6175]u16 = @import("razz_hashtable5.zig").razz_lookup5;
extern const razz_hashtable7: [49205]u16;
// const razz_hashtable7: [49205]u16 = @import("razz_hashtable7.zig").razz_lookup7;

pub const binaries_by_id = [_]u16{
    0x1,    0x1,    0x1,    0x1,
    0x2,    0x2,    0x2,    0x2,
    0x4,    0x4,    0x4,    0x4,
    0x8,    0x8,    0x8,    0x8,
    0x10,   0x10,   0x10,   0x10,
    0x20,   0x20,   0x20,   0x20,
    0x40,   0x40,   0x40,   0x40,
    0x80,   0x80,   0x80,   0x80,
    0x100,  0x100,  0x100,  0x100,
    0x200,  0x200,  0x200,  0x200,
    0x400,  0x400,  0x400,  0x400,
    0x800,  0x800,  0x800,  0x800,
    0x1000, 0x1000, 0x1000, 0x1000,
};

pub const suitbit_by_id = [_]u16{
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
    0x1, 0x8, 0x40, 0x200,
};

pub fn evaluate5Hand(hand: []const u8, comptime num_ranks: u8) Rank {
    std.debug.assert(hand.len == 10);
    var cards: [5]Card = undefined;
    for (cards) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate5Cards(cards[0], cards[1], cards[2], cards[3], cards[4], num_ranks);
}

pub fn evaluate7Hand(hand: []const u8, comptime num_ranks: u8) Rank {
    std.debug.assert(hand.len == 14);
    var cards: [7]Card = undefined;
    for (cards) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate7Cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], num_ranks);
}

pub fn evaluateOmahaHand(hand: []const u8) Rank {
    std.debug.assert(hand.len == 18);
    var cards: [9]Card = undefined;
    for (cards) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluateOmahaCards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], cards[7], cards[8]);
}

pub fn evaluateCards(cards: []const Card, comptime num_ranks: u8) Rank {
    // for (cards) |c| warn("{}, ", .{c.id});
    // warn("\n", .{});
    return switch (cards.len) {
        5 => evaluate5Cards(cards[0], cards[1], cards[2], cards[3], cards[4], num_ranks),
        7 => evaluate7Cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], num_ranks),
        else => @panic("only 5 and 7 card hands supported"),
    };
}
// Card id, ranged from 0 to 51.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-12.
// 13 * 4 gives 52 ids.
//
pub fn evaluate5Cards(a: Card, b: Card, c: Card, d: Card, e: Card, comptime num_ranks: u8) Rank {
    var suit_hash: u16 = 0;
    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary = [1]u16{0} ** 4;
        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];
        return Rank{ .value = flush[suit_binary[suit - 1]] };
    }

    var quinary = [1]u6{0} ** 13;
    quinary[a.id >> 2] += 1;
    quinary[b.id >> 2] += 1;
    quinary[c.id >> 2] += 1;
    quinary[d.id >> 2] += 1;
    quinary[e.id >> 2] += 1;

    const hash = hashQuinary(&quinary, num_ranks, 5);

    return Rank{ .value = noflush5[hash] };
}

pub fn evaluate7Cards(a: Card, b: Card, c: Card, d: Card, e: Card, f: Card, g: Card, comptime num_ranks: u8) Rank {
    var suit_hash: u16 = 0;

    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];
    suit_hash += suitbit_by_id[f.id];
    suit_hash += suitbit_by_id[g.id];

    const suit = suits[suit_hash];

    if (suit != 0) {
        var suit_binary = [1]u16{0} ** 4;

        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];
        suit_binary[f.id & 0x3] |= binaries_by_id[f.id];
        suit_binary[g.id & 0x3] |= binaries_by_id[g.id];

        return Rank{ .value = flush[suit_binary[suit - 1]] };
    }

    var quinary = [1]u6{0} ** 13;

    quinary[a.id >> 2] += 1;
    quinary[b.id >> 2] += 1;
    quinary[c.id >> 2] += 1;
    quinary[d.id >> 2] += 1;
    quinary[e.id >> 2] += 1;
    quinary[f.id >> 2] += 1;
    quinary[g.id >> 2] += 1;

    const hash = hashQuinary(&quinary, num_ranks, 7);

    return Rank{ .value = noflush7[hash] };
}

pub fn hashQuinary(q: []const u6, comptime len: u8, k_: u8) u32 {
    var sum: u32 = 0;
    comptime var i: u16 = 0;
    var k = k_;
    // std.debug.warn("hash_quinary {} {}\n", .{ len, k });

    inline while (i < len) : (i += 1) {
        // std.debug.warn("i {} ", .{i});
        // std.debug.warn("q[i] {} ", .{q[i]});
        // std.debug.warn("dp[q[i]] {}", .{dp[q[i]]});
        sum += dp[q[i]][len - i - 1][k];
        k -= q[i];
        if (k <= 0) break;
    }
    return sum;
}

pub fn hashBinary(binary: u16, comptime len: u8, k_: u8) u32 {
    var sum: u32 = 0;
    comptime var i: u4 = 0;
    var k = k_;

    inline while (i < len) : (i += 1) {
        if (binary & (@as(u15, 1) << i) != 0) {
            if (len - i - 1 >= k)
                sum += choose[len - i - 1][k];

            k -= 1;

            if (k == 0) break;
        }
    }

    return sum;
}

// Card id, ranged from 0 to 51.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-12.
// 13 * 4 gives 52 ids.
//
// The first five parameters are the community cards on the board
// The last four parameters are the hole cards of the player
//
pub fn evaluateOmahaCards(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card, h1: Card, h2: Card, h3: Card, h4: Card) Rank {
    var value_flush: u16 = 10000;
    var value_noflush: u16 = 10000;
    var suit_count_board = [1]u8{0} ** 4;
    var suit_count_hole = [1]u8{0} ** 4;

    suit_count_board[c1.id & 0x3] += 1;
    suit_count_board[c2.id & 0x3] += 1;
    suit_count_board[c3.id & 0x3] += 1;
    suit_count_board[c4.id & 0x3] += 1;
    suit_count_board[c5.id & 0x3] += 1;

    suit_count_hole[h1.id & 0x3] += 1;
    suit_count_hole[h2.id & 0x3] += 1;
    suit_count_hole[h3.id & 0x3] += 1;
    suit_count_hole[h4.id & 0x3] += 1;

    comptime var i: u8 = 0;
    inline while (i < 4) : (i += 1) {
        if (suit_count_board[i] >= 3 and suit_count_hole[i] >= 2) {
            var suit_binary_board = [1]u16{0} ** 4;

            suit_binary_board[c1.id & 0x3] |= binaries_by_id[c1.id];
            suit_binary_board[c2.id & 0x3] |= binaries_by_id[c2.id];
            suit_binary_board[c3.id & 0x3] |= binaries_by_id[c3.id];
            suit_binary_board[c4.id & 0x3] |= binaries_by_id[c4.id];
            suit_binary_board[c5.id & 0x3] |= binaries_by_id[c5.id];

            var suit_binary_hole = [1]u16{0} ** 4;
            suit_binary_hole[h1.id & 0x3] |= binaries_by_id[h1.id];
            suit_binary_hole[h2.id & 0x3] |= binaries_by_id[h2.id];
            suit_binary_hole[h3.id & 0x3] |= binaries_by_id[h3.id];
            suit_binary_hole[h4.id & 0x3] |= binaries_by_id[h4.id];

            if (suit_count_board[i] == 3 and suit_count_hole[i] == 2) {
                value_flush = flush[suit_binary_board[i] | suit_binary_hole[i]];
            } else {
                const padding = [3]u16{ 0x0000, 0x2000, 0x6000 };

                suit_binary_board[i] |= padding[5 - suit_count_board[i]];
                suit_binary_hole[i] |= padding[4 - suit_count_hole[i]];

                const board_hash = hashBinary(suit_binary_board[i], 15, 5);
                const hole_hash = hashBinary(suit_binary_hole[i], 15, 4);

                value_flush = flush_omaha[board_hash * 1365 + hole_hash];
            }

            break;
        }
    }

    var quinary_board = [1]u6{0} ** 13;
    var quinary_hole = [1]u6{0} ** 13;

    quinary_board[c1.id >> 2] += 1;
    quinary_board[c2.id >> 2] += 1;
    quinary_board[c3.id >> 2] += 1;
    quinary_board[c4.id >> 2] += 1;
    quinary_board[c5.id >> 2] += 1;

    quinary_hole[h1.id >> 2] += 1;
    quinary_hole[h2.id >> 2] += 1;
    quinary_hole[h3.id >> 2] += 1;
    quinary_hole[h4.id >> 2] += 1;

    const board_hash = hashQuinary(&quinary_board, 13, 5);
    const hole_hash = hashQuinary(&quinary_hole, 13, 4);

    value_noflush = noflush_omaha[board_hash * 1820 + hole_hash];

    return Rank.init(std.math.min(value_flush, value_noflush));
}

// EvSD5 Card id, ranged from 0 to 35.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-8.
// 9 * 4 gives 36 ids.
fn evaluate5Shortdeck(a: Card, b: Card, c: Card, d: Card, e: Card) Rank {
    var suit_hash: u16 = 0;
    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary = [1]u16{0} ** 4;
        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];
        // std.debug.warn("suit_binary[suit - 1] {}\n", .{suit_binary[suit - 1]});
        return Rank{ .value = flush_sd5[suit_binary[suit - 1]] };
    }

    var quinary = [1]u6{0} ** 9;
    quinary[a.id >> 2] += 1;
    quinary[b.id >> 2] += 1;
    quinary[c.id >> 2] += 1;
    quinary[d.id >> 2] += 1;
    quinary[e.id >> 2] += 1;

    const hash = hashQuinary(&quinary, 9, 5);

    return Rank{ .value = noflush_sd5[hash] };
}

// EvSD7 Card id, ranged from 0 to 35.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-8.
// 9 * 4 gives 36 ids.
fn evaluate7Shortdeck(a: Card, b: Card, c: Card, d: Card, e: Card, f: Card, g: Card) Rank {
    var suit_hash: u16 = 0;
    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];
    suit_hash += suitbit_by_id[f.id];
    suit_hash += suitbit_by_id[g.id];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary = [1]u16{0} ** 4;
        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];
        suit_binary[f.id & 0x3] |= binaries_by_id[f.id];
        suit_binary[g.id & 0x3] |= binaries_by_id[g.id];
        return Rank{ .value = flush_sd7[suit_binary[suit - 1]] };
    }

    var quinary = [1]u6{0} ** 9;
    quinary[a.id >> 2] += 1;
    quinary[b.id >> 2] += 1;
    quinary[c.id >> 2] += 1;
    quinary[d.id >> 2] += 1;
    quinary[e.id >> 2] += 1;
    quinary[f.id >> 2] += 1;
    quinary[g.id >> 2] += 1;

    const hash = hashQuinary(&quinary, 9, 7);

    return Rank{ .value = noflush_sd7[hash] };
}

pub fn evaluateCardsShortdeck(cards: []const Card) Rank {
    return switch (cards.len) {
        5 => evaluate5Shortdeck(cards[0], cards[1], cards[2], cards[3], cards[4]),
        7 => evaluate7Shortdeck(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]),
        else => @panic("only 5 and 7 card hands supported"),
    };
}

pub fn cardsToBinary(cards: []const Card) u16 {
    var result: u16 = 0;
    for (cards) |card| result |= binaries_by_id[card.id];
    return result;
}

pub fn evaluate5CardsRazz(a: Card, b: Card, c: Card, d: Card, e: Card) Rank {
    var quinary = [1]u6{0} ** 13;
    quinary[Card.rankToAlo(a.id >> 2)] += 1;
    quinary[Card.rankToAlo(b.id >> 2)] += 1;
    quinary[Card.rankToAlo(c.id >> 2)] += 1;
    quinary[Card.rankToAlo(d.id >> 2)] += 1;
    quinary[Card.rankToAlo(e.id >> 2)] += 1;
    const hash = hashQuinary(&quinary, 13, 5);
    // warn("hash {} razz_hashtable5[hash] {}\n", .{ hash, razz_hashtable5[hash] });

    return Rank.init(razz_hashtable5[hash]);
}

// TODO: replace with Vector(5, u6) once https://github.com/ziglang/zig/issues/3246 is resolved
const u8x5 = std.meta.Vector(5, u8);
pub fn evaluate5CardsRazzVec(a: Card, b: Card, c: Card, d: Card, e: Card) Rank {
    var ranks = u8x5{ a.id, b.id, c.id, d.id, e.id };
    ranks >>= @splat(5, @as(u3, 2));
    ranks += @splat(5, @as(u8, 1));
    ranks %= @splat(5, @as(u8, 13));
    var quinary = [1]u6{0} ** 13;
    comptime var i: u8 = 0;
    inline while (i < 5) : (i += 1) quinary[ranks[i]] += 1;
    const hash = hashQuinary(&quinary, 13, 5);
    // warn("hash {} razz_hashtable5[hash] {}\n", .{ hash, razz_hashtable5[hash] });

    return Rank.init(razz_hashtable5[hash]);
}

// evaluate the given 5 card hand and return a score from 0..6175
pub fn evaluateCardsRazz(cards: []const Card) Rank {
    return switch (cards.len) {
        5 => evaluate5CardsRazzVec(cards[0], cards[1], cards[2], cards[3], cards[4]),
        7 => evaluate7CardsRazzVec(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]),
        else => std.debug.panic("invalid cards length: {}", .{cards.len}),
    };
}

// TODO: replace with Vector(7, u6) once https://github.com/ziglang/zig/issues/3246 is resolved
const u8x7 = std.meta.Vector(7, u8);
pub fn evaluate7CardsRazzVec(a: Card, b: Card, c: Card, d: Card, e: Card, f: Card, g: Card) Rank {
    var ranks = u8x7{ a.id, b.id, c.id, d.id, e.id, f.id, g.id };
    ranks >>= @splat(7, @as(u3, 2));
    ranks += @splat(7, @as(u8, 1));
    ranks %= @splat(7, @as(u8, 13));
    var quinary = [1]u6{0} ** 13;
    comptime var i: u8 = 0;
    inline while (i < 7) : (i += 1) quinary[ranks[i]] += 1;
    const hash = hashQuinary(&quinary, 13, 7);
    // warn("hash {} razz_hashtable7[hash] {}\n", .{ hash, razz_hashtable7[hash] });

    return Rank.init(razz_hashtable7[hash]);
}

// evaluate the given 7 card hand and return a score from 0..5082
// pub fn evaluate7Razz(cards: []const Card) Rank {
//     std.debug.assert(cards.len == 7);
//     const alo_cards = Card.cardsToAlo(7, cards);
//     // for (alo_cards) |c| warn("alo c {}\n", .{c});
//     var quinary = [1]u6{0} ** 13;
//     quinary[alo_cards[0].id >> 2] += 1;
//     quinary[alo_cards[1].id >> 2] += 1;
//     quinary[alo_cards[2].id >> 2] += 1;
//     quinary[alo_cards[3].id >> 2] += 1;
//     quinary[alo_cards[4].id >> 2] += 1;
//     quinary[alo_cards[5].id >> 2] += 1;
//     quinary[alo_cards[6].id >> 2] += 1;
//     const hash = hashQuinary(&quinary, 13, 7);
//     // warn("hash {}\n", .{hash});

//     return Rank.init(razz_hashtable[hash]);
// }
