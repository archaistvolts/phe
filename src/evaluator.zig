const std = @import("std");
const warn = std.debug.warn;
const Card = @import("card.zig");
const Rank = @import("rank.zig");

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
extern const hashtable_razz5: [6175]u16;
// const hashtable_razz5: [6175]u16 = @import("hashtable_razz5.zig").razz_lookup5;
extern const hashtable_razz7: [49205]u16;
// const hashtable_razz7: [49205]u16 = @import("hashtable_razz7.zig").razz_lookup7;

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

pub fn evaluate5Hand(hand: []const u8, comptime R: u8) Rank {
    std.debug.assert(hand.len == 10);
    var cards: [5]u8 = undefined;
    for (&cards, 0..) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate5Cards(R, cards);
}

pub fn evaluate7Hand(hand: []const u8, comptime R: u8) Rank {
    std.debug.assert(hand.len == 14);
    var cards: [7]u8 = undefined;
    for (&cards, 0..) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate7Cards(R, cards);
}

pub fn evaluateOmahaHand(hand: []const u8) Rank {
    std.debug.assert(hand.len == 18);
    var cards: [9]u8 = undefined;
    for (&cards, 0..) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluateOmahaCards(cards);
}

pub fn evaluateCards(N: comptime_int, R: comptime_int, cards: [N]u8) Rank {
    return switch (cards.len) {
        5 => evaluate5Cards(R, cards),
        7 => evaluate7Cards(R, cards),
        else => @panic("only 5 and 7 card hands supported"),
    };
}
// Card id, ranged from 0 to 51.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-12.
// 13 * 4 gives 52 ids.
//
pub fn evaluate5Cards(R: comptime_int, cards: [5]u8) Rank {
    var suit_hash: u16 = 0;
    suit_hash += suitbit_by_id[cards[0]];
    suit_hash += suitbit_by_id[cards[1]];
    suit_hash += suitbit_by_id[cards[2]];
    suit_hash += suitbit_by_id[cards[3]];
    suit_hash += suitbit_by_id[cards[4]];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary: [4]u16 = @splat(0);
        suit_binary[cards[0] & 0x3] |= binaries_by_id[cards[0]];
        suit_binary[cards[1] & 0x3] |= binaries_by_id[cards[1]];
        suit_binary[cards[2] & 0x3] |= binaries_by_id[cards[2]];
        suit_binary[cards[3] & 0x3] |= binaries_by_id[cards[3]];
        suit_binary[cards[4] & 0x3] |= binaries_by_id[cards[4]];
        return Rank{ .value = flush[suit_binary[suit - 1]] };
    }

    var quinary: [13]u8 = @splat(0);
    quinary[cards[0] >> 2] += 1;
    quinary[cards[1] >> 2] += 1;
    quinary[cards[2] >> 2] += 1;
    quinary[cards[3] >> 2] += 1;
    quinary[cards[4] >> 2] += 1;

    const hash = hashQuinary(&quinary, R, 5);

    return Rank{ .value = noflush5[hash] };
}

pub fn evaluate7Cards(R: comptime_int, cards: [7]u8) Rank {
    var suit_hash: u16 = 0;

    suit_hash += suitbit_by_id[cards[0]];
    suit_hash += suitbit_by_id[cards[1]];
    suit_hash += suitbit_by_id[cards[2]];
    suit_hash += suitbit_by_id[cards[3]];
    suit_hash += suitbit_by_id[cards[4]];
    suit_hash += suitbit_by_id[cards[5]];
    suit_hash += suitbit_by_id[cards[6]];

    const suit = suits[suit_hash];

    if (suit != 0) {
        var suit_binary: [4]u16 = @splat(0);

        suit_binary[cards[0] & 0x3] |= binaries_by_id[cards[0]];
        suit_binary[cards[1] & 0x3] |= binaries_by_id[cards[1]];
        suit_binary[cards[2] & 0x3] |= binaries_by_id[cards[2]];
        suit_binary[cards[3] & 0x3] |= binaries_by_id[cards[3]];
        suit_binary[cards[4] & 0x3] |= binaries_by_id[cards[4]];
        suit_binary[cards[5] & 0x3] |= binaries_by_id[cards[5]];
        suit_binary[cards[6] & 0x3] |= binaries_by_id[cards[6]];

        return Rank{ .value = flush[suit_binary[suit - 1]] };
    }

    var quinary: [13]u8 = @splat(0);

    quinary[cards[0] >> 2] += 1;
    quinary[cards[1] >> 2] += 1;
    quinary[cards[2] >> 2] += 1;
    quinary[cards[3] >> 2] += 1;
    quinary[cards[4] >> 2] += 1;
    quinary[cards[5] >> 2] += 1;
    quinary[cards[6] >> 2] += 1;

    const hash = hashQuinary(&quinary, R, 7);

    return Rank{ .value = noflush7[hash] };
}

pub fn hashQuinary(q: [*]const u8, comptime len: u8, k_: u8) u32 {
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
pub fn evaluateOmahaCards(board_hole_cards: [9]u8) Rank {
    var value_flush: u16 = 10000;
    var value_noflush: u16 = 10000;
    var suit_count_board: [4]u8 = @splat(0);
    var suit_count_hole: [4]u8 = @splat(0);
    const c1, const c2, const c3, const c4, const c5, const h1, const h2, const h3, const h4 = board_hole_cards;

    suit_count_board[c1 & 0x3] += 1;
    suit_count_board[c2 & 0x3] += 1;
    suit_count_board[c3 & 0x3] += 1;
    suit_count_board[c4 & 0x3] += 1;
    suit_count_board[c5 & 0x3] += 1;

    suit_count_hole[h1 & 0x3] += 1;
    suit_count_hole[h2 & 0x3] += 1;
    suit_count_hole[h3 & 0x3] += 1;
    suit_count_hole[h4 & 0x3] += 1;

    var i: u8 = 0;
    while (i < 4) : (i += 1) {
        if (suit_count_board[i] >= 3 and suit_count_hole[i] >= 2) {
            var suit_binary_board: [4]u16 = @splat(0);

            suit_binary_board[c1 & 0x3] |= binaries_by_id[c1];
            suit_binary_board[c2 & 0x3] |= binaries_by_id[c2];
            suit_binary_board[c3 & 0x3] |= binaries_by_id[c3];
            suit_binary_board[c4 & 0x3] |= binaries_by_id[c4];
            suit_binary_board[c5 & 0x3] |= binaries_by_id[c5];

            var suit_binary_hole: [4]u16 = @splat(0);
            suit_binary_hole[h1 & 0x3] |= binaries_by_id[h1];
            suit_binary_hole[h2 & 0x3] |= binaries_by_id[h2];
            suit_binary_hole[h3 & 0x3] |= binaries_by_id[h3];
            suit_binary_hole[h4 & 0x3] |= binaries_by_id[h4];

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

    var quinary_board: [13]u8 = @splat(0);
    var quinary_hole: [13]u8 = @splat(0);

    quinary_board[c1 >> 2] += 1;
    quinary_board[c2 >> 2] += 1;
    quinary_board[c3 >> 2] += 1;
    quinary_board[c4 >> 2] += 1;
    quinary_board[c5 >> 2] += 1;

    quinary_hole[h1 >> 2] += 1;
    quinary_hole[h2 >> 2] += 1;
    quinary_hole[h3 >> 2] += 1;
    quinary_hole[h4 >> 2] += 1;

    const board_hash = hashQuinary(&quinary_board, 13, 5);
    const hole_hash = hashQuinary(&quinary_hole, 13, 4);

    value_noflush = noflush_omaha[board_hash * 1820 + hole_hash];

    return Rank.init(@min(value_flush, value_noflush));
}

// EvSD5 Card id, ranged from 0 to 35.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-8.
// 9 * 4 gives 36 ids.
pub fn evaluate5Shortdeck(cards: [5]u8) Rank {
    var suit_hash: u16 = 0;
    const a, const b, const c, const d, const e = cards;
    suit_hash += suitbit_by_id[a];
    suit_hash += suitbit_by_id[b];
    suit_hash += suitbit_by_id[c];
    suit_hash += suitbit_by_id[d];
    suit_hash += suitbit_by_id[e];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary: [4]u16 = @splat(0);
        suit_binary[a & 0x3] |= binaries_by_id[a];
        suit_binary[b & 0x3] |= binaries_by_id[b];
        suit_binary[c & 0x3] |= binaries_by_id[c];
        suit_binary[d & 0x3] |= binaries_by_id[d];
        suit_binary[e & 0x3] |= binaries_by_id[e];
        // std.debug.warn("suit_binary[suit - 1] {}\n", .{suit_binary[suit - 1]});
        return Rank{ .value = flush_sd5[suit_binary[suit - 1]] };
    }

    var quinary: [9]u8 = @splat(0);
    quinary[a >> 2] += 1;
    quinary[b >> 2] += 1;
    quinary[c >> 2] += 1;
    quinary[d >> 2] += 1;
    quinary[e >> 2] += 1;

    const hash = hashQuinary(&quinary, 9, 5);

    return Rank{ .value = noflush_sd5[hash] };
}

// EvSD7 Card id, ranged from 0 to 35.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-8.
// 9 * 4 gives 36 ids.
pub fn evaluate7Shortdeck(cards: [7]u8) Rank {
    const a, const b, const c, const d, const e, const f, const g = cards;
    var suit_hash: u16 = 0;
    suit_hash += suitbit_by_id[a];
    suit_hash += suitbit_by_id[b];
    suit_hash += suitbit_by_id[c];
    suit_hash += suitbit_by_id[d];
    suit_hash += suitbit_by_id[e];
    suit_hash += suitbit_by_id[f];
    suit_hash += suitbit_by_id[g];

    const suit = suits[suit_hash];
    if (suit != 0) {
        var suit_binary: [4]u16 = @splat(0);
        suit_binary[a & 0x3] |= binaries_by_id[a];
        suit_binary[b & 0x3] |= binaries_by_id[b];
        suit_binary[c & 0x3] |= binaries_by_id[c];
        suit_binary[d & 0x3] |= binaries_by_id[d];
        suit_binary[e & 0x3] |= binaries_by_id[e];
        suit_binary[f & 0x3] |= binaries_by_id[f];
        suit_binary[g & 0x3] |= binaries_by_id[g];
        return Rank{ .value = flush_sd7[suit_binary[suit - 1]] };
    }

    var quinary: [9]u8 = @splat(0);
    quinary[a >> 2] += 1;
    quinary[b >> 2] += 1;
    quinary[c >> 2] += 1;
    quinary[d >> 2] += 1;
    quinary[e >> 2] += 1;
    quinary[f >> 2] += 1;
    quinary[g >> 2] += 1;

    const hash = hashQuinary(&quinary, 9, 7);

    return Rank{ .value = noflush_sd7[hash] };
}

pub fn evaluateCardsShortdeck(cards: []const u8) Rank {
    return switch (cards.len) {
        5 => evaluate5Shortdeck(cards[0..5].*),
        7 => evaluate7Shortdeck(cards[0..7].*),
        else => @panic("only 5 and 7 card hands supported"),
    };
}

pub fn cardsToBinary(cards: []const u8) u16 {
    var result: u16 = 0;
    for (cards) |card| result |= binaries_by_id[card];
    return result;
}

pub fn evaluate5CardsRazz(cards: [5]u8) Rank {
    const a, const b, const c, const d, const e = cards;
    var quinary: [13]u8 = @splat(0);
    quinary[Card.rankToAlo(a >> 2)] += 1;
    quinary[Card.rankToAlo(b >> 2)] += 1;
    quinary[Card.rankToAlo(c >> 2)] += 1;
    quinary[Card.rankToAlo(d >> 2)] += 1;
    quinary[Card.rankToAlo(e >> 2)] += 1;
    const hash = hashQuinary(&quinary, 13, 5);
    // warn("hash {} hashtable_razz5[hash] {}\n", .{ hash, hashtable_razz5[hash] });

    return Rank.init(hashtable_razz5[hash]);
}

pub fn evaluate7CardsRazz(cards: [7]u8) Rank {
    var quinary: [13]u8 = @splat(0);
    quinary[Card.rankToAlo(cards[0] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[1] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[2] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[3] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[4] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[5] >> 2)] += 1;
    quinary[Card.rankToAlo(cards[6] >> 2)] += 1;
    const hash = hashQuinary(&quinary, 13, 7);
    // warn("hash {} hashtable_razz5[hash] {}\n", .{ hash, hashtable_razz5[hash] });

    return Rank.init(hashtable_razz7[hash]);
}

// TODO: replace with Vector(5, u8) once https://github.com/ziglang/zig/issues/3246 is resolved
const u8x5 = @Vector(5, u8);
pub fn evaluate5CardsRazzVec(cards: [5]u8) Rank {
    var ranks: u8x5 = cards;
    ranks >>= @splat(@as(u3, 2));
    ranks += @splat(@as(u8, 1));
    ranks %= @splat(@as(u8, 13));
    var quinary: [13]u8 = @splat(0);
    comptime var i: u8 = 0;
    inline while (i < 5) : (i += 1) quinary[ranks[i]] += 1;
    const hash = hashQuinary(&quinary, 13, 5);
    // warn("hash {} hashtable_razz5[hash] {}\n", .{ hash, hashtable_razz5[hash] });

    return Rank.init(hashtable_razz5[hash]);
}

// evaluate the given 5 card hand and return a score from 0..6175
pub fn evaluateCardsRazz(cards: []const u8) Rank {
    return switch (cards.len) {
        5 => evaluate5CardsRazzVec(cards[0..5].*),
        7 => evaluate7CardsRazzVec(cards[0..7].*),
        else => std.debug.panic("invalid cards length: {}", .{cards.len}),
    };
}

// TODO: replace with Vector(7, u8) once https://github.com/ziglang/zig/issues/3246 is resolved
const u8x7 = @Vector(7, u8);
pub fn evaluate7CardsRazzVec(cards: [7]u8) Rank {
    var ranks: u8x7 = cards;
    ranks >>= @splat(@as(u3, 2));
    ranks += @splat(@as(u8, 1));
    ranks %= @splat(@as(u8, 13));
    var quinary: [13]u8 = @splat(0);
    comptime var i: u8 = 0;
    inline while (i < 7) : (i += 1) quinary[ranks[i]] += 1;
    const hash = hashQuinary(&quinary, 13, 7);
    // warn("hash {} hashtable_razz7[hash] {}\n", .{ hash, hashtable_razz7[hash] });

    return Rank.init(hashtable_razz7[hash]);
}

// evaluate the given 7 card hand and return a score from 0..5082
// pub fn evaluate7Razz(cards: []const Card) Rank {
//     std.debug.assert(cards.len == 7);
//     const alo_cards = Card.cardsToAlo(7, cards);
//     // for (alo_cards) |c| warn("alo c {}\n", .{c});
//     var quinary = [1]u8{0} ** 13;
//     quinary[alo_cards[0] >> 2] += 1;
//     quinary[alo_cards[1] >> 2] += 1;
//     quinary[alo_cards[2] >> 2] += 1;
//     quinary[alo_cards[3] >> 2] += 1;
//     quinary[alo_cards[4] >> 2] += 1;
//     quinary[alo_cards[5] >> 2] += 1;
//     quinary[alo_cards[6] >> 2] += 1;
//     const hash = hashQuinary(&quinary, 13, 7);
//     // warn("hash {}\n", .{hash});

//     return Rank.init(hashtable_razz[hash]);
// }
