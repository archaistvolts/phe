const std = @import("std");
const Card = @import("card.zig");
const Rank = @import("rank.zig");
usingnamespace @import("tables.zig");

pub extern const flush: [8192]u16;
pub extern const noflush5: [6175]u16;
pub extern const noflush7: [49205]u16;
pub extern const choose: [53][10]u32;
pub extern const dp: [5][14][10]u32;
pub extern const suits: [4609]u8;

const binaries_by_id = [_]u16{
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

const suitbit_by_id = [_]u16{
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

pub fn evaluate_cards(cards: []Card) Rank {
    return switch (cards.len) {
        5 => evaluate_5cards(cards[0], cards[1], cards[2], cards[3], cards[4]),
        // 6 => evaluate_6cards(cards),
        7 => evaluate_7cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]),
        else => @panic("not implemented"),
    };
}
// Card id, ranged from 0 to 51.
// The two least significant bits represent the suit, ranged from 0-3.
// The rest of it represent the rank, ranged from 0-12.
// 13 * 4 gives 52 ids.
//
pub fn evaluate_5cards(a: Card, b: Card, c: Card, d: Card, e: Card) Rank {
    var suit_hash: u16 = 0;

    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];

    if (suits[suit_hash] != 0) {
        var suit_binary = [1]u16{0} ** 4;

        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];

        return Rank{ .value = flush[suit_binary[suits[suit_hash] - 1]] };
    }

    var quinary = [1]u8{0} ** 13;

    quinary[(a.id >> 2)] += 1;
    quinary[(b.id >> 2)] += 1;
    quinary[(c.id >> 2)] += 1;
    quinary[(d.id >> 2)] += 1;
    quinary[(e.id >> 2)] += 1;

    const hash = hash_quinary(&quinary, 5);

    return Rank{ .value = noflush5[hash] };
}

pub fn evaluate_7cards(a: Card, b: Card, c: Card, d: Card, e: Card, f: Card, g: Card) Rank {
    var suit_hash: u16 = 0;

    suit_hash += suitbit_by_id[a.id];
    suit_hash += suitbit_by_id[b.id];
    suit_hash += suitbit_by_id[c.id];
    suit_hash += suitbit_by_id[d.id];
    suit_hash += suitbit_by_id[e.id];
    suit_hash += suitbit_by_id[f.id];
    suit_hash += suitbit_by_id[g.id];

    if (suits[suit_hash] != 0) {
        var suit_binary = [1]u16{0} ** 4;

        suit_binary[a.id & 0x3] |= binaries_by_id[a.id];
        suit_binary[b.id & 0x3] |= binaries_by_id[b.id];
        suit_binary[c.id & 0x3] |= binaries_by_id[c.id];
        suit_binary[d.id & 0x3] |= binaries_by_id[d.id];
        suit_binary[e.id & 0x3] |= binaries_by_id[e.id];
        suit_binary[f.id & 0x3] |= binaries_by_id[f.id];
        suit_binary[g.id & 0x3] |= binaries_by_id[g.id];

        return Rank{ .value = flush[suit_binary[suits[suit_hash] - 1]] };
    }

    var quinary = [1]u8{0} ** 13;

    quinary[(a.id >> 2)] += 1;
    quinary[(b.id >> 2)] += 1;
    quinary[(c.id >> 2)] += 1;
    quinary[(d.id >> 2)] += 1;
    quinary[(e.id >> 2)] += 1;
    quinary[(f.id >> 2)] += 1;
    quinary[(g.id >> 2)] += 1;

    const hash = hash_quinary(&quinary, 7);

    return Rank{ .value = noflush7[hash] };
}

pub fn hash_quinary(q: []const u8, k_: u8) u32 {
    var sum: u32 = 0;
    const len: u16 = 13;
    var i: u16 = 0;
    var k = k_;

    while (i < len) : (i += 1) {
        sum += dp[q[i]][len - i - 1][k];
        k -= q[i];
        if (k <= 0) break;
    }

    return sum;
}

const ev5 = @import("phe.c.zig").ev5;

// compare against c version
test "EvaluateAll5" {
    var a: u7 = 0;
    while (a < 48) : (a += 1) {
        var b: u7 = a + 1;
        while (b < 49) : (b += 1) {
            var c: u7 = b + 1;
            while (c < 50) : (c += 1) {
                var d: u7 = c + 1;
                while (d < 51) : (d += 1) {
                    var e: u7 = d + 1;
                    while (e < 52) : (e += 1) {
                        const rank = evaluate_cards(&[_]Card{ Card.init(a), Card.init(b), Card.init(c), Card.init(d), Card.init(e) });
                        const c_rank = ev5.evaluate_5cards(a, b, c, d, e);
                        testing.expectEqual(rank.value, @intCast(u16, c_rank));
                    }
                }
            }
        }
    }
}

const ev7 = @import("phe.c.zig").ev7;

test "EvaluateAll7" {
    var a: u7 = 0;
    while (a < 46) : (a += 1) {
        var b: u7 = a + 1;
        while (b < 47) : (b += 1) {
            var c: u7 = b + 1;
            while (c < 48) : (c += 1) {
                var d: u7 = c + 1;
                while (d < 49) : (d += 1) {
                    var e: u7 = d + 1;
                    while (e < 50) : (e += 1) {
                        var f: u7 = e + 1;
                        while (f < 51) : (f += 1) {
                            var g: u7 = f + 1;
                            while (g < 52) : (g += 1) {
                                const rank = evaluate_cards(&[_]Card{ Card.init(a), Card.init(b), Card.init(c), Card.init(d), Card.init(e), Card.init(f), Card.init(g) });
                                const c_rank = ev7.evaluate_7cards(a, b, c, d, e, f, g);
                                testing.expectEqual(rank.value, @intCast(u16, c_rank));
                            }
                        }
                    }
                }
            }
        }
    }
}

pub fn hash_binary(binary: u16, k_: u8) u32 {
    var sum: u32 = 0;
    var i: u4 = 0;
    const len: u16 = 15;
    var k = k_;

    while (i < len) : (i += 1) {
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
pub fn evaluate_omaha_cards(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card, h1: Card, h2: Card, h3: Card, h4: Card) Rank {
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

    var i: u8 = 0;
    while (i < 4) : (i += 1) {
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

                const board_hash = hash_binary(suit_binary_board[i], 5);
                const hole_hash = hash_binary(suit_binary_hole[i], 4);

                value_flush = flush_omaha[board_hash * 1365 + hole_hash];
            }

            break;
        }
    }

    var quinary_board = [1]u8{0} ** 13;
    var quinary_hole = [1]u8{0} ** 13;

    quinary_board[(c1.id >> 2)] += 1;
    quinary_board[(c2.id >> 2)] += 1;
    quinary_board[(c3.id >> 2)] += 1;
    quinary_board[(c4.id >> 2)] += 1;
    quinary_board[(c5.id >> 2)] += 1;

    quinary_hole[(h1.id >> 2)] += 1;
    quinary_hole[(h2.id >> 2)] += 1;
    quinary_hole[(h3.id >> 2)] += 1;
    quinary_hole[(h4.id >> 2)] += 1;

    const board_hash = hash_quinary(&quinary_board, 5);
    const hole_hash = hash_quinary(&quinary_hole, 4);

    value_noflush = noflush_omaha[board_hash * 1820 + hole_hash];

    return Rank{
        .value = if (value_flush < value_noflush) value_flush else value_noflush,
    };
}

pub fn evaluate_omaha_cards_(c1: Card, c2: Card, c3: Card, c4: Card, c5: Card, h1: Card, h2: Card, h3: Card, h4: Card) Rank {
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

    var i: u8 = 0;
    while (i < 4) : (i += 1) {
        if (suit_count_board[i] >= 3 and suit_count_hole[i] >= 2) {}
    }
}

const testing = std.testing;
fn random_card_sample(comptime len: u8, al: *std.mem.Allocator) ![len]Card {
    var rand = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    var result: [len]Card = undefined;
    var map = std.AutoHashMap(u7, void).init(al);
    defer map.deinit();
    while (map.count() < len) {
        const i = rand.random.intRangeLessThan(u7, 0, 52);
        _ = try map.put(i, {});
    }
    var it = map.iterator();
    var i: u8 = 0;
    while (it.next()) |kv| : (i += 1) {
        result[i] = Card.init(kv.key);
    }
    return result;
}

const evo = @import("phe.c.zig").evaluate_omaha_cards;

test "EvaluateRandomOmahaCards" {
    var al = testing.LeakCountAllocator.init(std.heap.c_allocator);
    var count: u16 = 0;
    while (count < 1000) : (count += 1) {
        var hands = std.ArrayList([9]Card).init(&al.allocator);
        const size = 100;

        var i: u8 = 0;
        while (i < size) : (i += 1)
            _ = try hands.append(try random_card_sample(9, &al.allocator));

        i = 0;
        while (i < size) : (i += 1) {
            const rank = evaluate_omaha_cards(hands.items[i][0], hands.items[i][1], hands.items[i][2], hands.items[i][3], hands.items[i][4], hands.items[i][5], hands.items[i][6], hands.items[i][7], hands.items[i][8]);
            // var buf: [18]u8 = undefined;
            // var buf2: [18]u8 = undefined;
            // std.debug.warn("{} board {} hold {}\n", .{ rank.category().describe(), Card.describe_cards(hands.items[i][0..5], &buf), Card.describe_cards(hands.items[i][5..], &buf2) });
            const c_rank = evo(@intCast(c_int, hands.items[i][0].id), @intCast(c_int, hands.items[i][1].id), @intCast(c_int, hands.items[i][2].id), @intCast(c_int, hands.items[i][3].id), @intCast(c_int, hands.items[i][4].id), @intCast(c_int, hands.items[i][5].id), @intCast(c_int, hands.items[i][6].id), @intCast(c_int, hands.items[i][7].id), @intCast(c_int, hands.items[i][8].id));
            testing.expectEqual(rank.value, @intCast(u16, c_rank));
        }
        hands.deinit();
        try al.validate();
    }
}
