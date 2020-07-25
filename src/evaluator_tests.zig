const std = @import("std");
const warn = std.debug.warn;

const Card = @import("card.zig");
const Rank = @import("rank.zig");
usingnamespace @import("evaluator.zig");
const ev5 = @import("phe.c.zig").ev5;
const ev7 = @import("phe.c.zig").ev7;
const util = @import("util.zig");

// compare against c version
test "evAll5" {
    var fuzz_num_hands: usize = 0;
    var total_time: u64 = 0;
    defer printBencharkInfo(total_time, fuzz_num_hands, 5, "evaluateCards");
    var a: u6 = 0;
    var tmr = try std.time.Timer.start();
    while (a < 48) : (a += 1) {
        var b: u6 = a + 1;
        while (b < 49) : (b += 1) {
            var c: u6 = b + 1;
            while (c < 50) : (c += 1) {
                var d: u6 = c + 1;
                while (d < 51) : (d += 1) {
                    var e: u6 = d + 1;
                    while (e < 52) : (e += 1) {
                        tmr.reset();
                        const rank = evaluateCards(&[_]Card{ Card.init(a), Card.init(b), Card.init(c), Card.init(d), Card.init(e) }, 13);
                        total_time += tmr.read();
                        const c_rank = ev5.evaluate_5cards(a, b, c, d, e);
                        testing.expectEqual(rank.value, @intCast(u16, c_rank));
                        fuzz_num_hands += 1;
                    }
                }
            }
        }
    }
}

test "evAll7" {
    var fuzz_num_hands: usize = 0;
    var total_time: u64 = 0;
    defer printBencharkInfo(total_time, fuzz_num_hands, 7, "evaluateCards");
    var tmr = try std.time.Timer.start();

    var a: u6 = 0;
    while (a < 46) : (a += 1) {
        var b: u6 = a + 1;
        while (b < 47) : (b += 1) {
            var c: u6 = b + 1;
            while (c < 48) : (c += 1) {
                var d: u6 = c + 1;
                while (d < 49) : (d += 1) {
                    var e: u6 = d + 1;
                    while (e < 50) : (e += 1) {
                        var f: u6 = e + 1;
                        while (f < 51) : (f += 1) {
                            var g: u6 = f + 1;
                            while (g < 52) : (g += 1) {
                                tmr.reset();
                                const rank = evaluateCards(&[_]Card{ Card.init(a), Card.init(b), Card.init(c), Card.init(d), Card.init(e), Card.init(f), Card.init(g) }, 13);
                                total_time += tmr.read();
                                const c_rank = ev7.evaluate_7cards(a, b, c, d, e, f, g);
                                testing.expectEqual(rank.value, @intCast(u16, c_rank));
                                fuzz_num_hands += 1;
                            }
                        }
                    }
                }
            }
        }
    }
}

const testing = std.testing;
fn randomCardSample(comptime len: u8, al: *std.mem.Allocator, low: u6, hi: u6) ![len]Card {
    var rand = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    var result: [len]Card = undefined;
    var map = std.AutoHashMap(u6, void).init(al);
    defer map.deinit();
    while (map.count() < len) {
        const i = rand.random.intRangeLessThan(u6, low, hi);
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

test "fuzz5" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try randomCardSample(5, std.heap.c_allocator, 0, 52);
        const rank = evaluate5Cards(hand[0], hand[1], hand[2], hand[3], hand[4], 13);
        const c_rank = ev5.evaluate_5cards(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "fuzz7" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try randomCardSample(7, std.heap.c_allocator, 0, 52);
        const rank = evaluate7Cards(hand[0], hand[1], hand[2], hand[3], hand[4], hand[5], hand[6], 13);
        const c_rank = ev7.evaluate_7cards(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id), @intCast(c_int, hand[5].id), @intCast(c_int, hand[6].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "fuzz omaha" {
    var trial: usize = 0;
    while (trial < num_trials) : (trial += 1) {
        const hand = try randomCardSample(9, std.heap.c_allocator, 0, 52);
        const rank = evaluateOmahaCards(hand[0], hand[1], hand[2], hand[3], hand[4], hand[5], hand[6], hand[7], hand[8]);
        const c_rank = evo(@intCast(c_int, hand[0].id), @intCast(c_int, hand[1].id), @intCast(c_int, hand[2].id), @intCast(c_int, hand[3].id), @intCast(c_int, hand[4].id), @intCast(c_int, hand[5].id), @intCast(c_int, hand[6].id), @intCast(c_int, hand[7].id), @intCast(c_int, hand[8].id));
        testing.expectEqual(rank.value, @intCast(u16, c_rank));
    }
}

test "holdem" {
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
    islessRk(hi_seven, hi_ace, "");
    islessRk(hi_ace, pr, "");
    islessRk(pr, pr2, "");
    islessRk(pr2, pr3, "");
    islessRk(pr3, pr4, "");
    islessRk(pr4, pr5, "");
    islessRk(pr5, pr6, "");
    islessRk(pr6, pr7, "");
    islessRk(pr6, two_pr1, "");
    islessRk(two_pr1, two_pr2, "");
    islessRk(two_pr2, two_pr3, "");
    islessRk(two_pr3, three_kind1, "");
    islessRk(three_kind1, three_kind2, "");
    islessRk(three_kind2, three_kind3, "");
    islessRk(three_kind3, straight_wheel, "");
    islessRk(straight_wheel, straight, "");
    islessRk(straight, straight_broadway, "");
    islessRk(straight_broadway, flush0, "");
    islessRk(flush0, flush_k_hi, "");
    islessRk(flush_k_hi, flush_a_hi, "");
    islessRk(flush_a_hi, full_house1, "");
    islessRk(full_house1, full_house2, "");
    islessRk(full_house2, four_kind1, "");
    islessRk(four_kind1, four_kind2, "");
    islessRk(four_kind2, four_kind3, "");
    islessRk(four_kind3, StraightFlush_wheel, "");
    islessRk(StraightFlush_wheel, StraightFlush1, "");
    islessRk(StraightFlush1, StraightFlush_royal, "");
    islessRk(StraightFlush1, StraightFlush_royal, "");

    islessRk(hh2, hh1, ajq23_b);
    islessRk(hh3, hh2, ajq23_b);
    islessRk(hh4, hh3, ajq23_b);
}

fn islessRk(comptime l: []const u8, comptime h: []const u8, comptime b: []const u8) void {
    const lf = b ++ l;
    const hf = b ++ h;
    std.debug.assert(lf.len == hf.len);
    const evfn = switch (lf.len) {
        10 => evaluate5Hand,
        14 => evaluate7Hand,
        else => @panic("invalid hand length"),
    };
    const lr = evfn(lf, 13); // catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ lf);
    const hr = evfn(hf, 13); // catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ hf);
    if (lr.value < hr.value) {
        std.debug.warn("{} {} should be less than {} {}", .{ l, lr, h, hr });
        testing.expect(lr.value >= hr.value);
    }
}

test "omaha" {
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

    // const s = EvOmaha([]const u8Ha&ndCodes(oh11), []c&onst u8Ha&ndCodes(oh_b1), true)&.Lo;
    // if s != MaxScore {
    // 	t.Fatalf("omaha no lo failed, low score {}", s)
    // }

    islessRkOmaha(oh4, oh3, ajq23_b);
    islessRkOmaha(oh3, oh2, ajq23_b);
    islessRkOmaha(oh2, oh1, ajq23_b);
    islessRkOmaha(oh4, oh1, four_flush_b);

    isRankClassOh(.two_pair, oh4, four_flush_b);
    isRankClassOh(.one_pair, oh5, five_flush_b);
    isRankClassOh(.three_of_a_kind, oh6, two_pr_b);

    // omaha lo tests
    // isless_rkomaha(oh10, oh9, lo_b2);
    // isless_rkomaha(oh6, oh10, lo_b2);
    // isless_rkomaha(oh6, oh10, lo_b);
    // // is_rank_class_oh(TwoPair, oh7, lo_b, t)
    // // is_rank_class_oh(TwoPair, oh8, lo_b, t)
}

fn islessRkOmaha(comptime l: []const u8, comptime h: []const u8, comptime board: []const u8) void {
    const lr = evaluateOmahaHand(board ++ l); // catch @panic("isless_rkomaha invalid hand: " ++ board ++ l);
    const hr = evaluateOmahaHand(board ++ h); // catch @panic("isless_rkomaha invalid hand: " ++ board ++ h);
    if (lr.value < lr.value) {
        const ld = lr.category().describe();
        const hd = lr.category().describe();
        std.debug.warn("{} {} {} should lose to {} {} {} board {}", .{ l, lr, ld, h, hr, hd, board });
    }
    // else if hilo == 1 and lr.Lo < lr.Lo {
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

fn handToCards(comptime hand_len: u8, hand: []const u8) [hand_len]Card {
    std.debug.assert(hand_len * 2 == hand.len);
    var cards: [hand_len]Card = undefined;
    for (cards) |*card, i| card.* = Card.initFromName(hand[i * 2 .. i * 2 + 2]);
    return cards;
}

fn isRankClassOh(c: Rank.Category, comptime h: []const u8, comptime board: []const u8) void {
    const r = evaluateOmahaHand(board ++ h); // catch @panic("is_rank_class_oh invalid hand: " ++ board ++ h);
    const rc = r.category();
    if (rc != c) {
        const cd = c.describe();
        const rcd = rc.describe();
        // t.Fatalf("{} is not rank class {} {} {}", cd, rcd, h, board)
        const cards = handToCards(9, board ++ h);
        const r2 = evo(@intCast(c_int, cards[0].id), @intCast(c_int, cards[1].id), @intCast(c_int, cards[2].id), @intCast(c_int, cards[3].id), @intCast(c_int, cards[4].id), @intCast(c_int, cards[5].id), @intCast(c_int, cards[6].id), @intCast(c_int, cards[7].id), @intCast(c_int, cards[8].id));
        const rc2 = Rank{ .value = @intCast(u16, r2) };
        std.debug.warn("expected {} but got {} hand {} board {}. c rank class: {}", .{ cd, rcd, h, board, rc2.category() });
        testing.expect(rc == c);
    }
}

fn makeFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res = [1]u8{'s'} ** ranks.len ** 2;
    for (ranks) |rk, i| res[i * 2] = rk;
    return res;
}

fn makeNonFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res: [ranks.len * 2]u8 = undefined;
    for (ranks) |rk, i| std.mem.copy(u8, res[i * 2 .. i * 2 + 2], &[2]u8{ rk, Card.suitToName(@intCast(u2, i % 4)) });
    return res;
}

test "shortdeck" {
    const HCB = struct { c: Rank.Category, lo: [10]u8, hi: [10]u8, lo7: *const [14]u8, hi7: *const [14]u8 };
    const handClassBoundaries = [_]HCB{
        .{ .c = .straight_flush, .lo = makeFlush("A6789"), .hi = makeFlush("TJQKA"), .lo7 = "Ad6d7d8d9dJsQs", .hi7 = "ThJhQhKhAhJsQs" },
        .{ .c = .four_of_a_kind, .lo = makeNonFlush("66667"), .hi = makeNonFlush("AAAAK"), .lo7 = "6h6s6d6c7h7d7s", .hi7 = "AhAsAdAcKh7d7s" },
        .{ .c = .flush, .lo = makeFlush("6789J"), .hi = makeFlush("9JQKA"), .lo7 = "6s7s8s9sJsQdKd", .hi7 = "9hJhQhKhAhQdKd" },
        .{ .c = .full_house, .lo = makeNonFlush("66677"), .hi = makeNonFlush("AAAKK"), .lo7 = "6h6s6d7c7hQdJc", .hi7 = "AhAsAdKcKhQdJc" },
        .{ .c = .straight, .lo = makeNonFlush("6789T"), .hi = makeNonFlush("TJQKA"), .lo7 = "Ad6s7d8s9s9h9c", .hi7 = "ThJdQhKhAhAdAc" },
        .{ .c = .three_of_a_kind, .lo = makeNonFlush("66678"), .hi = makeNonFlush("AAAKQ"), .lo7 = "6h6s6d8c7hThJc", .hi7 = "AhAsAdQcKhTh9c" },
        .{ .c = .two_pair, .lo = makeNonFlush("66778"), .hi = makeNonFlush("AAKKQ"), .lo7 = "6h6s7d7h8cJdQc", .hi7 = "AhAsKdKhQdJd9c" },
        .{ .c = .one_pair, .lo = makeNonFlush("66789"), .hi = makeNonFlush("AAKQJ"), .lo7 = "6h6s7d8c9dKcJd", .hi7 = "AhAsKdQdJh9c8s" },
        .{ .c = .high_card, .lo = makeNonFlush("6789J"), .hi = makeNonFlush("9JQKA"), .lo7 = "6s7s8s9sJdQhKd", .hi7 = "7c8s9hJhQhKhAd" },
    };
    // for each category, compare against previous
    // check that rank < rank_prev
    var i: usize = 0;
    while (i < handClassBoundaries.len) : (i += 1) {
        const hcb = handClassBoundaries[i];
        var hand_prev_lo: []const u8 = "?????";
        var hand_prev_hi: []const u8 = "?????";
        var rank_prev_lo = Rank.init(0);
        var rank_prev_hi = Rank.init(0);
        var hand_prev_lo7: []const u8 = "???????";
        var hand_prev_hi7: []const u8 = "???????";
        var rank_prev_lo7 = Rank.init(0);
        var rank_prev_hi7 = Rank.init(0);

        if (i > 0) {
            hand_prev_lo = &handClassBoundaries[i - 1].lo;
            hand_prev_hi = &handClassBoundaries[i - 1].hi;
            rank_prev_lo = evaluateCardsShortdeck(&Card.cardsFromStringSd(5, hand_prev_lo));
            rank_prev_hi = evaluateCardsShortdeck(&Card.cardsFromStringSd(5, hand_prev_hi));
            hand_prev_lo7 = handClassBoundaries[i - 1].lo7;
            hand_prev_hi7 = handClassBoundaries[i - 1].hi7;
            rank_prev_lo7 = evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hand_prev_lo7));
            rank_prev_hi7 = evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hand_prev_hi7));
        }

        const r1 = evaluateCardsShortdeck(&Card.cardsFromStringSd(5, &hcb.lo));
        const r2 = evaluateCardsShortdeck(&Card.cardsFromStringSd(5, &hcb.hi));
        const r3 = evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hcb.lo7));
        const r4 = evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hcb.hi7));
        const category = hcb.c;
        const cmpClass = struct {
            fn _(c: Rank.Category, r: Rank, hand: []const u8, rprev_lo: Rank, hprev_lo: []const u8, rprev_hi: Rank, hprev_hi: []const u8) void {
                const category_sd = r.categoryToSd();
                if (c != category_sd) {
                    std.debug.warn("category mismatch expected {} got {} hand {} rank {} range {}-{} \n", .{ c.describe(), category_sd.describe(), hand, r.value, c.begin(), c.end() });
                    testing.expect(c == category_sd);
                }
                if (!(c.beginSdAdjusted() < r.value and r.value <= c.endSdAdjusted())) {
                    std.debug.warn("hand rank outside category range. category {} hand {} rank {} range {}-{}\n", .{ r.category().describe(), hand, r.value, c.beginSdAdjusted(), c.endSdAdjusted() });
                    testing.expect(c.beginSdAdjusted() < r.value and r.value <= c.endSdAdjusted());
                }
                if (r.value <= rprev_lo.value) {
                    std.debug.warn("{} rank {} {} <= {} {} {}\n", .{ r.category().describe(), r.value, hand, rprev_lo.value, hprev_lo, rprev_lo.category().describe() });
                    testing.expect(r.value > rprev_lo.value);
                }
                if (r.value <= rprev_hi.value) {
                    std.debug.warn("{} rank {} {} <= {} {} {}\n", .{ r.category().describe(), r.value, hand, rprev_hi.value, hprev_hi, rprev_hi.category().describe() });
                    testing.expect(r.value > rprev_hi.value);
                }
            }
        }._;
        cmpClass(category, r1, &hcb.lo, rank_prev_lo, hand_prev_lo, rank_prev_hi, hand_prev_hi);
        cmpClass(category, r2, &hcb.hi, rank_prev_lo, hand_prev_lo, rank_prev_hi, hand_prev_hi);
        cmpClass(category, r3, hcb.lo7, rank_prev_lo7, hand_prev_lo7, rank_prev_hi7, hand_prev_hi7);
        cmpClass(category, r4, hcb.hi7, rank_prev_lo7, hand_prev_lo7, rank_prev_hi7, hand_prev_hi7);
    }
}

fn printDebugInfo(comptime ev_name: []const u8, len: usize, h: []Card, h2: []Card, rank: Rank, rank2: Rank, rank_sd: Rank, rank_sd2: Rank, cat: Rank.Category, cat2: Rank.Category, sdcat: Rank.Category, sd2cat: Rank.Category, bin: u16, bin2: u16) void {
    var buf: [20]u8 = undefined;
    var buf2: [20]u8 = undefined;
    const cardsToSFn = if (std.meta.eql(ev_name, "sd")) Card.cardsToStringSd else Card.cardsToString;
    std.debug.warn("\nevaluate{}{12} didn't match evaluate{} ({}  {}) {12} ({}-{} {}-{}) expected ({}-{} {}-{})\n", .{
        len,                 len,
        cardsToSFn(h, &buf), cardsToSFn(h2, &buf2),
        rank_sd.value,       sdcat.describe(),
        rank_sd2.value,      sd2cat.describe(),
        rank.value,          cat.describe(),
        rank2.value,         cat2.describe(),
        ev_name,
    });
    std.debug.warn("bin {b:0<9} bin2 {b:0<9}\n", .{ bin, bin2 });
}

const EvCardsFn = fn ([]Card) Rank;
const EvCardsLenFn = fn ([]Card, u8) Rank;
// const fuzz_num_hands = 100_000;

/// fuzz test short deck evaluations
/// Compare short deck evaluation of every possible hand against random hand
/// by making sure both are <= or both are >=.
/// This won't hold for a6789 straights and straight flushes or flush vs full house comparisons
/// so these are validated differently.
fn sdTest(comptime len: u8, ev_fn_name: []const u8) !void {
    const evfn: EvCardsFn = evaluateCardsShortdeck;
    const expected_evfn: EvCardsLenFn = evaluateCards;
    const combFn = if (len == 5) util.comb5 else if (len == 7) util.comb7 else @panic("unsupported length");
    const allocator = std.heap.page_allocator;
    var total_time: u64 = 0;
    var fuzz_num_hands: usize = 0;
    defer printBencharkInfo(total_time, fuzz_num_hands, len, ev_fn_name);
    var i: usize = 0;
    var chan: std.event.Channel(?[len]u6) = undefined;
    chan.init(&[_]?[len]u6{});
    _ = async combFn(0, 36, &chan);
    var tmr = try std.time.Timer.start();
    while (chan.get()) |ids| : (fuzz_num_hands += 1) {
        var h = Card.cardsFromIds(len, &ids);
        var h2 = randomCardSample(len, allocator, 0, 36) catch @panic("error in randomCardSample");

        tmr.reset();
        const sdrank = evfn(&h);
        total_time += tmr.read();
        const sdrank2 = evfn(&h2);

        const rank = expected_evfn(&h, 13);
        const rank2 = expected_evfn(&h2, 13);

        const sdcat = sdrank.categoryToSd();
        const sdcat2 = sdrank2.categoryToSd();
        const cat = rank.category();
        const cat2 = rank2.category();

        var classes = [_]Rank.Category{ sdcat, sdcat2, cat, cat2 };
        // fail on any invalid ranks
        if (std.mem.indexOfScalar(Rank.Category, &classes, .invalid)) |_| testing.expect(false);
        const both_lte = sdrank.value <= sdrank2.value and rank.value <= rank2.value;
        const both_gte = sdrank.value >= sdrank2.value and rank.value >= rank2.value;
        if (!(both_gte or both_lte)) {
            const bin = cardsToBinary(&h);
            const bin2 = cardsToBinary(&h2);
            const wheel_mask = 0b100001111;
            const h_is_wheel = bin & wheel_mask == wheel_mask;
            const h2_is_wheel = bin2 & wheel_mask == wheel_mask;
            if (h_is_wheel or h2_is_wheel) {
                if (h_is_wheel) {
                    const expected = sdcat == .straight or sdcat == .straight_flush;
                    if (sdcat == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                    else if (!expected) {
                        printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        testing.expect(expected);
                    }
                }
                if (h2_is_wheel) {
                    const expected = sdcat2 == .straight or sdcat2 == .straight_flush;
                    if (sdcat2 == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                    else if (!expected) {
                        printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        testing.expect(expected);
                    }
                }
            } else if (std.mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .flush, .full_house, .flush, .full_house })) {
                const expected = sdrank.value < sdrank2.value and rank.value > rank2.value;
                if (!expected) {
                    printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                    testing.expect(expected);
                }
            } else if (std.mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .full_house, .flush, .full_house, .flush })) {
                const expected = sdrank.value > sdrank2.value and rank.value < rank2.value;
                if (!expected) {
                    printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                    testing.expect(expected);
                }
            } else {
                printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                testing.expect(false);
            }
        }
    }
}

fn printBencharkInfo(total_time: u64, fuzz_num_hands: usize, len: usize, ev_fn_name: []const u8) void {
    const total_seconds = @intToFloat(f32, total_time) / @intToFloat(f32, std.time.ns_per_s);
    const hands_per_s = @intToFloat(f32, fuzz_num_hands) / total_seconds / 1000;

    std.debug.warn("{}-{} cards {d:.1} Khands/s\n", .{ ev_fn_name, len, hands_per_s });
}

test "fuzz shortdeck5" {
    try sdTest(5, "evaluateShortdeck");
}

test "fuzz shortdeck7" {
    try sdTest(7, "evaluateShortdeck");
}

test "razz ev5" {
    const hands = .{
        "5432a", "6432a", "6532a", "6542a", "6543a", "65432", "7432a", "7543a", "75432", "7632a", "7642a",
        "7643a", "76432", "7652a", "7653a", "7654a", "76542", "76543", "8432a", "8532a", "8542a", "8543a",
        "85432", "89tjq", "8tjqk", "9tjqk", "aa234", "aa235", "aajkq", "22a34", "22a35", "22jkq", "aa223",
        "aa224", "aa22k", "qqkka", "qqkk2", "qqkkj", "aaa22", "aaa33", "22233", "22244", "jjjqq", "jjjkk",
        "qqqkk", "qqkkk", "aaaa2", "aaaa3", "kkkkj", "kkkkq",
    };
    inline for (.{ makeFlush, makeNonFlush }) |makeFn| {
        const cards_wheel = Card.cardsFromString(5, &makeFn(hands[0]));
        // for (cards_wheel) |c| warn("c {}\n", .{c});
        testing.expectEqual(evaluateCardsRazz(&cards_wheel).value, 1);
        inline for (hands) |h, i| {
            if (i == 0) continue;
            const r = evaluateCardsRazz(&Card.cardsFromString(5, &makeFn(h)));
            const r_prev = evaluateCardsRazz(&Card.cardsFromString(5, &makeFn(hands[i - 1])));
            const expected = r_prev.value < r.value;
            // warn("h {}-{} h_prev {}-{}\n", .{ h, r.value, hands[i - 1], r_prev.value });
            if (!expected) testing.expect(expected);
        }
    }
}

fn razzFuzzTest(comptime len: u8, ev_fn_name: []const u8) !void {
    const evfn: EvCardsFn = evaluateCardsRazz;
    const expected_evfn: EvCardsLenFn = evaluateCards;
    const combFn = if (len == 5) util.comb5 else if (len == 7) util.comb7 else @panic("unsupported length");
    const allocator = std.heap.page_allocator;
    var total_time: u64 = 0;
    var fuzz_num_hands: usize = 0;
    defer printBencharkInfo(total_time, fuzz_num_hands, len, ev_fn_name);
    var chan: std.event.Channel(?[len]u6) = undefined;
    chan.init(&[_]?[len]u6{});
    _ = async combFn(0, 52, &chan);
    var tmr = try std.time.Timer.start();
    while (chan.get()) |ids| : (fuzz_num_hands += 1) {
        var h = Card.cardsFromIds(len, &ids);
        var h2 = randomCardSample(len, allocator, 0, 52) catch @panic("error in randomCardSample");

        tmr.reset();
        const rzrank = evfn(&h);
        total_time += tmr.read();
        const rzrank2 = evfn(&h2);

        var rank = expected_evfn(&Card.cardsToAlo(5, &h), 13);
        var rank2 = expected_evfn(&Card.cardsToAlo(5, &h2), 13);
        // skip straights and flushes
        const ignore_categories = &[_]Rank.Category{ .straight_flush, .flush, .straight };
        if (std.mem.indexOfScalar(Rank.Category, ignore_categories, rank.category()) != null) continue;
        if (std.mem.indexOfScalar(Rank.Category, ignore_categories, rank2.category()) != null) continue;

        const cat = rank.category();
        const cat2 = rank2.category();

        const both_lte = rzrank.value >= rzrank2.value and rank.value <= rank2.value;
        const both_gte = rzrank.value <= rzrank2.value and rank.value >= rank2.value;

        if (!(both_gte or both_lte)) {
            printDebugInfo("razz", len, &h, &h2, rank, rank2, rzrank, rzrank2, cat, cat2, .invalid, .invalid, 0, 0);
            testing.expect(false);
        }
    }
}

test "fuzz razz 5" {
    try razzFuzzTest(5, "evaluateCardsRazz");
}
