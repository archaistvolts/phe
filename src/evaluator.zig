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

pub fn evaluate_5hand(hand: []const u8) !Rank {
    std.debug.assert(hand.len == 10);
    var cards: [5]Card = undefined;
    for (cards) |*card, i| card.* = try Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate_5cards(cards[0], cards[1], cards[2], cards[3], cards[4]);
}

pub fn evaluate_7hand(hand: []const u8) !Rank {
    std.debug.assert(hand.len == 14);
    var cards: [7]Card = undefined;
    for (cards) |*card, i| card.* = try Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate_7cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]);
}

pub fn evaluate_omaha_hand(hand: []const u8) !Rank {
    std.debug.assert(hand.len == 18);
    var cards: [9]Card = undefined;
    for (cards) |*card, i| card.* = try Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return evaluate_omaha_cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], cards[7], cards[8]);
}

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

    const hash = hash_quinary(&quinary, 13, 5);

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

    const hash = hash_quinary(&quinary, 13, 7);

    return Rank{ .value = noflush7[hash] };
}

pub fn hash_quinary(q: []const u8, comptime len: u8, k_: u8) u32 {
    var sum: u32 = 0;
    // const len: u16 = 13;
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

    const board_hash = hash_quinary(&quinary_board, 13, 5);
    const hole_hash = hash_quinary(&quinary_hole, 13, 4);

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

const num_trials = 100_000;

test "Fuzz5" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try random_card_sample(5, std.heap.c_allocator);
        const rank = evaluate_5cards(hand[0], hand[1], hand[2], hand[3], hand[4]);
        const c_rank = ev5.evaluate_5cards(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "Fuzz7" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try random_card_sample(7, std.heap.c_allocator);
        const rank = evaluate_7cards(hand[0], hand[1], hand[2], hand[3], hand[4], hand[5], hand[6]);
        const c_rank = ev7.evaluate_7cards(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id), @intCast(c_int, hand[5].id), @intCast(c_int, hand[6].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "FuzzOmaha" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try random_card_sample(9, std.heap.c_allocator);
        const rank = evaluate_omaha_cards(hand[0], hand[1], hand[2], hand[3], hand[4], hand[5], hand[6], hand[7], hand[8]);
        const c_rank = evo(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id), @intCast(c_int, hand[5].id), @intCast(c_int, hand[6].id), @intCast(c_int, hand[7].id), @intCast(c_int, hand[8].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "TestHoldem" {
    const hi_seven = "2h3s4c5c7d";
    const hi_ace = "AhJsQcKc9d";
    const pr = "2h2s4c5c7d";
    const pr2 = "2h2sAcKcQd";
    const pr3 = "3h3s4c5c6d";
    const pr4 = "4c6c6hJsKc";
    const pr5 = "3h4h7c7d8h";
    const pr6 = "KhKs4c5c7d";
    const pr7 = "AhAsKcQcJd";
    const two_pr1 = "2h2s3c3d4d";
    const two_pr2 = "2h2s4c4dAd";
    const two_pr3 = "AhAsQcQdKd";
    const three_kind1 = "2h2s2c4d5d";
    const three_kind2 = "ThTsTc4d7d";
    const three_kind3 = "AhAsAcKdQd";
    const straight_wheel = "2h3s5c4dAd";
    const straight = "2h3s6c5d4d";
    const straight_broadway = "KhQsTcJdAd";
    const flush0 = "2h4h5h9h7h";
    const flush_a_hi = "2h4h5h9hAh";
    const flush_k_hi = "2h4h5h9hKh";
    const full_house1 = "2h5d2d2c5s";
    const full_house2 = "8h7d8d8c7s";
    const four_kind1 = "2h2s2c2d3d";
    const four_kind2 = "9h9s9c9d7d";
    const four_kind3 = "9h9s9c9d8d";
    const StraightFlush1 = "2h3h6h5h4h";
    const StraightFlush_wheel = "2d3d4d5dAd";
    const StraightFlush_royal = "TsAsQsKsJs";
    const ajq23_b = "AhJsQc2c3c";
    const hh1 = "KcTc";
    const hh2 = "AsQd";
    const hh3 = "AdJc";
    const hh4 = "AsTc";

    // simple 5 card hands
    isless_rk(hi_seven, hi_ace, "");
    isless_rk(hi_ace, pr, "");
    isless_rk(pr, pr2, "");
    isless_rk(pr2, pr3, "");
    isless_rk(pr3, pr4, "");
    isless_rk(pr4, pr5, "");
    isless_rk(pr5, pr6, "");
    isless_rk(pr6, pr7, "");
    isless_rk(pr6, two_pr1, "");
    isless_rk(two_pr1, two_pr2, "");
    isless_rk(two_pr2, two_pr3, "");
    isless_rk(two_pr3, three_kind1, "");
    isless_rk(three_kind1, three_kind2, "");
    isless_rk(three_kind2, three_kind3, "");
    isless_rk(three_kind3, straight_wheel, "");
    isless_rk(straight_wheel, straight, "");
    isless_rk(straight, straight_broadway, "");
    isless_rk(straight_broadway, flush0, "");
    isless_rk(flush0, flush_k_hi, "");
    isless_rk(flush_k_hi, flush_a_hi, "");
    isless_rk(flush_a_hi, full_house1, "");
    isless_rk(full_house1, full_house2, "");
    isless_rk(full_house2, four_kind1, "");
    isless_rk(four_kind1, four_kind2, "");
    isless_rk(four_kind2, four_kind3, "");
    isless_rk(four_kind3, StraightFlush_wheel, "");
    isless_rk(StraightFlush_wheel, StraightFlush1, "");
    isless_rk(StraightFlush1, StraightFlush_royal, "");
    isless_rk(StraightFlush1, StraightFlush_royal, "");

    isless_rk(hh2, hh1, ajq23_b);
    isless_rk(hh3, hh2, ajq23_b);
    isless_rk(hh4, hh3, ajq23_b);
}

fn isless_rk(comptime l: []const u8, comptime h: []const u8, comptime b: []const u8) void {
    const lf = b ++ l;
    const hf = b ++ h;
    std.debug.assert(lf.len == hf.len);
    const ev_fn = switch (lf.len) {
        10 => evaluate_5hand,
        14 => evaluate_7hand,
        else => @panic("invalid hand length"),
    };
    const lr = ev_fn(lf) catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ lf);
    const hr = ev_fn(hf) catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ hf);
    if (lr.value < hr.value) {
        std.debug.warn("{} {} should be less than {} {}", .{ l, lr, h, hr });
        testing.expect(lr.value >= hr.value);
    }
}

test "Omaha" {
    // omaha 9 card with board
    const ajq23_b = "AhJsQc2c3c";
    const oh1 = "AcTc9d9h";
    const oh2 = "KcTc9d9h";
    const oh3 = "KhTs9d9h";
    const oh4 = "AcQh9d9h";
    const four_flush_b = "AhJcQc2c3c";
    const five_flush_b = "AcJcQc2c3c";
    const oh5 = "KcQh9d9h";
    const two_pr_b = "AcAd9h9d9s";
    const lo_b = "2c3d4s5c7h";
    const lo_b2 = "2c3d7sTcKh";
    const oh6 = "AhJcQdTh";
    const oh7 = "2d3h8d9h";
    const oh8 = "AsKh2sKd";
    const oh9 = "AsKh4sKd";
    const oh10 = "AsKh5sKd";
    const oh_b1 = "8hTs9c9h3s";
    const oh11 = "4h6d9sJc";

    // const s = EvOmaha(StringHandCodes(oh11), StringHandCodes(oh_b1), true).Lo;
    // if s != MaxScore {
    // 	t.Fatalf("omaha no lo failed, low score {}", s)
    // }

    isless_rkomaha(oh4, oh3, ajq23_b);
    isless_rkomaha(oh3, oh2, ajq23_b);
    isless_rkomaha(oh2, oh1, ajq23_b);
    isless_rkomaha(oh4, oh1, four_flush_b);

    is_rank_class_oh(.two_pair, oh4, four_flush_b);
    is_rank_class_oh(.one_pair, oh5, five_flush_b);
    is_rank_class_oh(.three_of_a_kind, oh6, two_pr_b);

    // omaha lo tests
    // isless_rkomaha(oh10, oh9, lo_b2);
    // isless_rkomaha(oh6, oh10, lo_b2);
    // isless_rkomaha(oh6, oh10, lo_b);
    // // is_rank_class_oh(TwoPair, oh7, lo_b, t)
    // // is_rank_class_oh(TwoPair, oh8, lo_b, t)
}

fn isless_rkomaha(comptime l: []const u8, comptime h: []const u8, comptime board: []const u8) void {
    const lr = evaluate_omaha_hand(board ++ l) catch @panic("isless_rkomaha invalid hand: " ++ board ++ l);
    const hr = evaluate_omaha_hand(board ++ h) catch @panic("isless_rkomaha invalid hand: " ++ board ++ h);
    if (lr.value < lr.value) {
        const ld = lr.category().describe();
        const hd = lr.category().describe();
        std.debug.warn("{} {} {} should lose to {} {} {} board {}", .{ l, lr, ld, h, hr, hd, board });
    }
    // else if hilo == 1 && lr.Lo < lr.Lo {
    // 	ld := RankDescription(lr.Lo)
    // 	hd := RankDescription(hr.Lo)
    // 	t.Fatalf("{} {} {} should lose to {} {} {} board {}", .{l, lr, ld, h, hr, hd, board});
    // }

    // if lr[hilo] < hr[hilo] {
    // 	ld := RankDescription(lr[hilo])
    // 	hd := RankDescription(hr[hilo])
    // 	t.Fatalf("{} {} {} should lose to {} {} {} board {}", l, lr, ld, h, hr, hd, board)
    // }
}

fn hand_to_cards(comptime hand_len: u8, hand: []const u8) [hand_len]Card {
    std.debug.assert(hand_len * 2 == hand.len);
    var cards: [hand_len]Card = undefined;
    for (cards) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]) catch @panic("bad card");
    return cards;
}

fn is_rank_class_oh(c: Rank.rank_category, comptime h: []const u8, comptime board: []const u8) void {
    const r = evaluate_omaha_hand(board ++ h) catch @panic("is_rank_class_oh invalid hand: " ++ board ++ h);
    const rc = r.category();
    if (rc != c) {
        const cd = c.describe();
        const rcd = rc.describe();
        // t.Fatalf("{} is not rank class {} {} {}", cd, rcd, h, board)
        const cards = hand_to_cards(9, board ++ h);
        const r2 = evo(@intCast(c_int, cards[0].id), @intCast(c_int, cards[1].id), @intCast(c_int, cards[2].id), @intCast(c_int, cards[3].id), @intCast(c_int, cards[4].id), @intCast(c_int, cards[5].id), @intCast(c_int, cards[6].id), @intCast(c_int, cards[7].id), @intCast(c_int, cards[8].id));
        const rc2 = Rank{ .value = @intCast(u16, r2) };
        std.debug.warn("expected {} but got {} hand {} board {}. c rank class: {}", .{ cd, rcd, h, board, rc2.category() });
        testing.expect(rc == c);
    }
}
