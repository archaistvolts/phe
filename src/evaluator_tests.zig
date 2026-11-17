const TestCtx = struct {
    hand_idx: usize,
    max_hand_idx: usize = std.math.maxInt(usize),
    total_time: Io.Duration,
    map: *Map,
    rand: std.Random.DefaultPrng,
    pub const Map = std.AutoHashMap(u8, void);
    pub fn init(map: *Map, io: Io) !TestCtx {
        return TestCtx{
            .hand_idx = 0,
            .total_time = .fromNanoseconds(0),
            .rand = .init(@intCast(Io.Timestamp.now(io, .cpu_process).toMilliseconds())),
            .map = map,
        };
    }
};

// compare against c version
test "validate 5" {
    // std.log.warn("validate 5\n", .{});
    const cb = struct {
        fn func(ids: [5]u8, ctx: anytype) !bool {
            _ = ctx;
            const actual = ev.evaluate5Cards(13, ids);
            const expected = phe_c.evaluate_5cards(ids[0], ids[1], ids[2], ids[3], ids[4]);
            try testing.expectEqual(@as(u16, @intCast(expected)), actual.value);
            return true;
        }
    }.func;
    try util.comb5Cb(0, 52, cb, {});
}

test "validate 7" {
    // std.log.warn("validate 7\n", .{});
    const cb = struct {
        fn func(ids: [7]u8, ctx: anytype) !bool {
            _ = ctx;
            // const actual = wrap7(evaluate7Cards, 13)(Card.cardsFromIds(7, &ids));
            const actual = ev.evaluate7Cards(13, ids);
            const expected = phe_c.evaluate_7cards(ids[0], ids[1], ids[2], ids[3], ids[4], ids[5], ids[6]);
            try testing.expectEqual(@as(u16, @intCast(expected)), actual.value);
            return true;
        }
    }.func;
    try util.comb7Cb(0, 52, cb, {});
}

fn evaluate5CardsC(R: comptime_int, cards: [5]u8) Rank {
    _ = R;
    return Rank.init(@as(u16, @intCast(phe_c.evaluate_5cards(
        @as(c_int, cards[0]),
        @as(c_int, cards[1]),
        @as(c_int, cards[2]),
        @as(c_int, cards[3]),
        @as(c_int, cards[4]),
    ))));
}

fn printBencharkInfo(total_time: Io.Duration, hand_idx: usize, ev_fn_name: []const u8) void {
    const total_useconds = @as(f64, @floatFromInt(Io.Duration.fromNanoseconds(total_time.nanoseconds).toMicroseconds()));
    const hands_per_s: u64 = @intFromFloat(@as(f64, @floatFromInt(hand_idx)) / total_useconds * std.time.us_per_s);
    std.debug.print("{s: <20} {B:.1} hands/s hands {B:.1} total_time {f}\n", .{ ev_fn_name, hand_idx, hands_per_s, total_time });
}

const benchmark_num_trials = 100;

fn evaluate7CardsC(R: comptime_int, cards: [7]u8) Rank {
    _ = R;
    return Rank.init(@as(u16, @intCast(phe_c.evaluate_7cards(
        cards[0],
        cards[1],
        cards[2],
        cards[3],
        cards[4],
        cards[5],
        cards[6],
    ))));
}

const testing = std.testing;

fn randomCardSample(comptime len: u8, map: *std.AutoHashMap(u8, void), rand: std.Random, low: u8, hi: u8) ![len]u8 {
    var result: [len]u8 = undefined;
    map.clearRetainingCapacity();
    while (map.count() < len) {
        const i = rand.intRangeLessThan(u8, low, hi);
        _ = map.putAssumeCapacity(i, {});
    }
    var it = map.iterator();
    var i: u8 = 0;
    while (it.next()) |kv| : (i += 1) {
        result[i] = kv.key_ptr.*;
    }
    return result;
}

test "validate omaha" {
    // std.log.warn("validate omaha\n", .{});
    var map = std.AutoHashMap(u8, void).init(std.heap.c_allocator);
    defer map.deinit();
    var ctx = try TestCtx.init(&map, testing.io);
    try ctx.map.ensureTotalCapacity(9);
    while (ctx.hand_idx < benchmark_num_trials) : (ctx.hand_idx += 1) {
        const cards = try randomCardSample(9, ctx.map, ctx.rand.random(), 0, 52);
        const actual = ev.evaluateOmahaCards(cards);
        const expected = phe_c.evaluate_omaha_cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], cards[7], cards[8]);
        try testing.expectEqual(@as(u16, @intCast(expected)), actual.value);
    }
}

fn evaluateOmahaCardsC(board_hole_cards: [9]u8) Rank {
    return Rank.init(@as(u16, @intCast(phe_c.evaluate_omaha_cards(
        board_hole_cards[0],
        board_hole_cards[1],
        board_hole_cards[2],
        board_hole_cards[3],
        board_hole_cards[4],
        board_hole_cards[5],
        board_hole_cards[6],
        board_hole_cards[7],
        board_hole_cards[8],
    ))));
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
    const strt_flush1 = "2h3h6h5h4h";
    const strt_flush_wheel = "2d3d4d5dAd";
    const strt_flush_royal = "TsAsQsKsJs";
    const ajq23_b = "AhJsQc2c3c";
    const hh1 = "KcTc";
    const hh2 = "AsQd";
    const hh3 = "AdJc";
    const hh4 = "AsTc";

    // simple 5 card hands
    try islessRk(hi_seven, hi_ace, "");
    try islessRk(hi_ace, pr, "");
    try islessRk(pr, pr2, "");
    try islessRk(pr2, pr3, "");
    try islessRk(pr3, pr4, "");
    try islessRk(pr4, pr5, "");
    try islessRk(pr5, pr6, "");
    try islessRk(pr6, pr7, "");
    try islessRk(pr6, two_pr1, "");
    try islessRk(two_pr1, two_pr2, "");
    try islessRk(two_pr2, two_pr3, "");
    try islessRk(two_pr3, three_kind1, "");
    try islessRk(three_kind1, three_kind2, "");
    try islessRk(three_kind2, three_kind3, "");
    try islessRk(three_kind3, straight_wheel, "");
    try islessRk(straight_wheel, straight, "");
    try islessRk(straight, straight_broadway, "");
    try islessRk(straight_broadway, flush0, "");
    try islessRk(flush0, flush_k_hi, "");
    try islessRk(flush_k_hi, flush_a_hi, "");
    try islessRk(flush_a_hi, full_house1, "");
    try islessRk(full_house1, full_house2, "");
    try islessRk(full_house2, four_kind1, "");
    try islessRk(four_kind1, four_kind2, "");
    try islessRk(four_kind2, four_kind3, "");
    try islessRk(four_kind3, strt_flush_wheel, "");
    try islessRk(strt_flush_wheel, strt_flush1, "");
    try islessRk(strt_flush1, strt_flush_royal, "");
    try islessRk(strt_flush1, strt_flush_royal, "");

    try islessRk(hh2, hh1, ajq23_b);
    try islessRk(hh3, hh2, ajq23_b);
    try islessRk(hh4, hh3, ajq23_b);
}

fn islessRk(comptime l: []const u8, comptime h: []const u8, comptime b: []const u8) !void {
    const lf = b ++ l;
    const hf = b ++ h;
    std.debug.assert(lf.len == hf.len);
    const evfn = switch (lf.len) {
        10 => ev.evaluate5Hand,
        14 => ev.evaluate7Hand,
        else => @panic("invalid hand length"),
    };
    const lr = evfn(lf, 13); // catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ lf);
    const hr = evfn(hf, 13); // catch |e| @panic("error: invalid hand passed to evaluate_5hand. " ++ hf);
    if (lr.value < hr.value) {
        std.debug.print("{s} {} should be less than {s} {}", .{ l, lr, h, hr });
        try testing.expect(lr.value >= hr.value);
    }
}

test "omaha ranks" {
    // std.log.warn("omaha\n", .{});
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
    _ = oh7;
    const oh8 = "AsKh2sKd";
    _ = oh8;
    const oh9 = "AsKh4sKd";
    const oh10 = "AsKh5sKd";
    const oh_b1 = "8hTs9c9h3s";
    _ = oh_b1;
    const oh11 = "4h6d9sJc";
    _ = oh11;

    // if s := EvOmaha(StringHandCodes(oh11), StringHandCodes(oh_b1), true).Lo; s != MaxScore {
    //     t.Fatalf("omaha no lo failed, low score %d", s)
    // }

    try islessRkOmaha(oh4, oh3, ajq23_b, .hi);
    try islessRkOmaha(oh3, oh2, ajq23_b, .hi);
    try islessRkOmaha(oh2, oh1, ajq23_b, .hi);
    try islessRkOmaha(oh4, oh1, four_flush_b, .hi);

    try isRankClassOh(.two_pair, oh4, four_flush_b);
    try isRankClassOh(.one_pair, oh5, five_flush_b);
    try isRankClassOh(.three_of_a_kind, oh6, two_pr_b);

    // omaha lo tests
    try islessRkOmaha(oh10, oh9, lo_b2, .lo);
    try islessRkOmaha(oh6, oh10, lo_b2, .lo);
    try islessRkOmaha(oh6, oh10, lo_b, .lo);
    // try isRankClassOh(.two_pair, oh7, lo_b);
    // try isRankClassOh(.two_pair, oh8, lo_b);
}

fn islessRkOmaha(comptime l: []const u8, comptime h: []const u8, comptime board: []const u8, comptime hilo: enum { hi, lo }) !void {
    const lr = ev.evaluateOmahaHand(board ++ l);
    const hr = ev.evaluateOmahaHand(board ++ h);
    if (hilo == .hi and lr.value < hr.value) {
        const ld = lr.category().describe();
        const hd = lr.category().describe();
        std.debug.print(
            "{s} {} {s} should lose to {s} {} {s} board {s}",
            .{ l, lr, ld, h, hr, hd, board },
        );
    } else if (hilo == .lo and lr.value < lr.value) {
        const ld = lr.category().describe();
        const hd = hr.category().describe();
        std.debug.print(
            "{s} {} {s} should lose to {s} {} {s} board {s}",
            .{ l, lr, ld, h, hr, hd, board },
        );
    }
}

fn isRankClassOh(c: Rank.Category, comptime h: []const u8, comptime board: []const u8) !void {
    const r = ev.evaluateOmahaHand(board ++ h);
    const rc = r.category();
    if (rc != c) {
        const cd = c.describe();
        const rcd = rc.describe();
        const cards = Card.cardsFromString(9, board ++ h);
        const r2 = phe_c.evaluate_omaha_cards(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], cards[7], cards[8]);
        const rc2 = Rank{ .value = @as(u16, @intCast(r2)) };
        std.debug.print(
            "expected {s} but got {s} hand {s} board {s}. c rank class: {}",
            .{ cd, rcd, h, board, rc2.category() },
        );
        try testing.expect(rc == c);
    }
}

fn makeFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res: [ranks.len * 2]u8 = @splat('s');
    for (ranks, 0..) |rk, i| res[i * 2] = rk;
    return res;
}

fn makeNonFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res: [ranks.len * 2]u8 = undefined;
    for (ranks, 0..) |rk, i|
        @memcpy(res[i * 2 .. i * 2 + 2], &[2]u8{ rk, Card.suitToName(@as(u2, @intCast(i % 4))) });
    return res;
}

test "shortdeck" {
    // std.log.warn("shortdeck\n", .{});
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
            rank_prev_lo = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(5, hand_prev_lo));
            rank_prev_hi = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(5, hand_prev_hi));
            hand_prev_lo7 = handClassBoundaries[i - 1].lo7;
            hand_prev_hi7 = handClassBoundaries[i - 1].hi7;
            rank_prev_lo7 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hand_prev_lo7));
            rank_prev_hi7 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hand_prev_hi7));
        }

        const r1 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(5, &hcb.lo));
        const r2 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(5, &hcb.hi));
        const r3 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hcb.lo7));
        const r4 = ev.evaluateCardsShortdeck(&Card.cardsFromStringSd(7, hcb.hi7));
        const category = hcb.c;
        const cmpClass = struct {
            fn _(c: Rank.Category, r: Rank, hand: []const u8, rprev_lo: Rank, hprev_lo: []const u8, rprev_hi: Rank, hprev_hi: []const u8) !void {
                const category_sd = r.categoryToSd();
                if (c != category_sd) {
                    std.debug.print(
                        "category mismatch expected {s} got {s} hand {s} rank {} range {}-{} \n",
                        .{ c.describe(), category_sd.describe(), hand, r.value, c.begin(), c.end() },
                    );
                    try testing.expect(c == category_sd);
                }
                if (!(c.beginSdAdjusted() < r.value and r.value <= c.endSdAdjusted())) {
                    std.debug.print(
                        "hand rank outside category range. category {s} hand {s} rank {} range {}-{}\n",
                        .{ r.category().describe(), hand, r.value, c.beginSdAdjusted(), c.endSdAdjusted() },
                    );
                    try testing.expect(c.beginSdAdjusted() < r.value and r.value <= c.endSdAdjusted());
                }
                if (r.value <= rprev_lo.value) {
                    std.debug.print("{s} rank {} {s} <= {} {s} {s}\n", .{ r.category().describe(), r.value, hand, rprev_lo.value, hprev_lo, rprev_lo.category().describe() });
                    try testing.expect(r.value > rprev_lo.value);
                }
                if (r.value <= rprev_hi.value) {
                    std.debug.print(
                        "{s} rank {} {s} <= {} {s} {s}\n",
                        .{ r.category().describe(), r.value, hand, rprev_hi.value, hprev_hi, rprev_hi.category().describe() },
                    );
                    try testing.expect(r.value > rprev_hi.value);
                }
            }
        }._;
        try cmpClass(category, r1, &hcb.lo, rank_prev_lo, hand_prev_lo, rank_prev_hi, hand_prev_hi);
        try cmpClass(category, r2, &hcb.hi, rank_prev_lo, hand_prev_lo, rank_prev_hi, hand_prev_hi);
        try cmpClass(category, r3, hcb.lo7, rank_prev_lo7, hand_prev_lo7, rank_prev_hi7, hand_prev_hi7);
        try cmpClass(category, r4, hcb.hi7, rank_prev_lo7, hand_prev_lo7, rank_prev_hi7, hand_prev_hi7);
    }
}

fn printDebugInfo(comptime ev_name: []const u8, len: usize, h: []const u8, h2: []const u8, rank: Rank, rank2: Rank, rank_sd: Rank, rank_sd2: Rank, cat: Rank.Category, cat2: Rank.Category, sdcat: Rank.Category, sd2cat: Rank.Category, bin: u16, bin2: u16) void {
    var buf: [20]u8 = undefined;
    var buf2: [20]u8 = undefined;
    const cardsToSFn = if (comptime std.mem.eql(u8, ev_name, "sd")) Card.cardsToStringSd else Card.cardsToString;
    std.debug.print("\nevaluate{}{12s} didn't match evaluate{} ({s}  {s}) {12s} ({}-{s} {}-{s}) expected ({}-{s} {}-{s})\n", .{
        len,                 len,
        cardsToSFn(h, &buf), cardsToSFn(h2, &buf2),
        rank_sd.value,       sdcat.describe(),
        rank_sd2.value,      sd2cat.describe(),
        rank.value,          cat.describe(),
        rank2.value,         cat2.describe(),
        ev_name,
    });
    std.debug.print("bin {b:0<9} bin2 {b:0<9}\n", .{ bin, bin2 });
}

/// fuzz test short deck evaluations
/// Compare short deck evaluation of every possible hand against random hand
/// by making sure both are <= or both are >=.
/// This won't hold for a6789 straights and straight flushes or flush vs full house comparisons
/// so these are validated differently.
fn sdTest(comptime len: u8, comptime ev_fn_name: []const u8) !void {
    _ = ev_fn_name;
    const cb = struct {
        fn func(ids: [len]u8, ctx: anytype) !bool {
            var h2 = randomCardSample(len, ctx.map, ctx.rand.random(), 0, 36) catch @panic("error in randomCardSample");

            const sdrank = if (len == 5) ev.evaluate5Shortdeck(ids) else ev.evaluate7Shortdeck(ids);
            const sdrank2 = if (len == 5) ev.evaluate5Shortdeck(h2) else ev.evaluate7Shortdeck(h2);

            const rank = if (len == 5) ev.evaluate5Cards(13, ids) else ev.evaluate7Cards(13, ids);
            const rank2 = if (len == 5) ev.evaluate5Cards(13, h2) else ev.evaluate7Cards(13, h2);

            const sdcat = sdrank.categoryToSd();
            const sdcat2 = sdrank2.categoryToSd();
            const cat = rank.category();
            const cat2 = rank2.category();

            var classes = [_]Rank.Category{ sdcat, sdcat2, cat, cat2 };
            // fail on any invalid ranks
            if (std.mem.indexOfScalar(Rank.Category, &classes, .invalid)) |_| try testing.expect(false);
            const both_lte = sdrank.value <= sdrank2.value and rank.value <= rank2.value;
            const both_gte = sdrank.value >= sdrank2.value and rank.value >= rank2.value;
            if (!(both_gte or both_lte)) {
                const bin = ev.cardsToBinary(&ids);
                const bin2 = ev.cardsToBinary(&h2);
                const wheel_mask = 0b100001111;
                const h_is_wheel = bin & wheel_mask == wheel_mask;
                const h2_is_wheel = bin2 & wheel_mask == wheel_mask;
                if (h_is_wheel or h2_is_wheel) {
                    if (h_is_wheel) {
                        const expected = sdcat == .straight or sdcat == .straight_flush;
                        if (sdcat == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                        else if (!expected) {
                            printDebugInfo("sd", len, &ids, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                            try testing.expect(expected);
                        }
                    }
                    if (h2_is_wheel) {
                        const expected = sdcat2 == .straight or sdcat2 == .straight_flush;
                        if (sdcat2 == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                        else if (!expected) {
                            printDebugInfo("sd", len, &ids, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                            try testing.expect(expected);
                        }
                    }
                } else if (std.mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .flush, .full_house, .flush, .full_house })) {
                    const expected = sdrank.value < sdrank2.value and rank.value > rank2.value;
                    if (!expected) {
                        printDebugInfo("sd", len, &ids, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        try testing.expect(expected);
                    }
                } else if (std.mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .full_house, .flush, .full_house, .flush })) {
                    const expected = sdrank.value > sdrank2.value and rank.value < rank2.value;
                    if (!expected) {
                        printDebugInfo("sd", len, &ids, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        try testing.expect(expected);
                    }
                } else {
                    printDebugInfo("sd", len, &ids, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                    try testing.expect(false);
                }
            }
            return true;
        }
    }.func;

    var map = std.AutoHashMap(u8, void).init(std.heap.c_allocator);
    defer map.deinit();
    var ctx = try TestCtx.init(&map, testing.io);
    try ctx.map.ensureTotalCapacity(len);
    const combFn = if (len == 5) util.comb5Cb else if (len == 7) util.comb7Cb else @panic("unsupported length");
    try combFn(0, 36, cb, &ctx);
}

test "fuzz shortdeck5" {
    // std.log.warn("fuzz shortdeck5\n", .{});
    try sdTest(5, "evaluateShortdeck");
}

test "fuzz shortdeck7" {
    // std.log.warn("fuzz shortdeck7\n", .{});
    try sdTest(7, "evaluateShortdeck");
}

test "razz ev5" {
    // std.log.warn("razz ev5\n", .{});
    const hands = .{
        "5432a", "6432a", "6532a", "6542a", "6543a", "65432", "7432a", "7543a", "75432", "7632a", "7642a",
        "7643a", "76432", "7652a", "7653a", "7654a", "76542", "76543", "8432a", "8532a", "8542a", "8543a",
        "85432", "89tjq", "8tjqk", "9tjqk", "aa234", "aa235", "aajkq", "22a34", "22a35", "22jkq", "aa223",
        "aa224", "aa22k", "qqkka", "qqkk2", "qqkkj", "aaa22", "aaa33", "22233", "22244", "jjjqq", "jjjkk",
        "qqqkk", "qqkkk", "aaaa2", "aaaa3", "kkkkj", "kkkkq",
    };
    inline for (.{ makeFlush, makeNonFlush }) |makeFn| {
        const cards_wheel = Card.cardsFromString(5, &makeFn(hands[0]));
        // for (cards_wheel) |c| print("c {}\n", .{c});
        try testing.expectEqual(ev.evaluateCardsRazz(&cards_wheel).value, 1);
        inline for (hands, 0..) |h, i| {
            if (i == 0) continue;
            const r = ev.evaluateCardsRazz(&Card.cardsFromString(5, &makeFn(h)));
            const r_prev = ev.evaluateCardsRazz(&Card.cardsFromString(5, &makeFn(hands[i - 1])));
            const expected = r_prev.value < r.value;
            // print("h {}-{} h_prev {}-{}\n", .{ h, r.value, hands[i - 1], r_prev.value });
            if (!expected) try testing.expect(expected);
        }
    }
}

fn razzValidate(comptime len: u8, ev_fn_name: []const u8, cb: anytype) !void {
    _ = ev_fn_name;
    var map = std.AutoHashMap(u8, void).init(std.heap.c_allocator);
    defer map.deinit();
    var ctx = try TestCtx.init(&map, testing.io);
    try ctx.map.ensureTotalCapacity(len);
    const combFn = if (len == 5) util.comb5Cb else if (len == 7) util.comb7Cb else @panic("unsupported length");
    if (len == 7) ctx.max_hand_idx = 1_000_000;
    try combFn(0, 52, cb, &ctx);
}

const lessthan_rank_alo = @import("gen.zig").lessthan_rank_alo;

fn asc_alo_hands(context: void, a: []const u8, b: []const u8) bool {
    _ = context;
    for (a, 0..) |ae, i| {
        const be = b[i];
        if (ae == be) continue;
        return lessthan_rank_alo({}, ae, be);
    }
    return false;
}

test "validate razz 5" {
    // std.log.warn("validate razz 5\n", .{});
    const len = 5;
    const evfn = ev.evaluateCardsRazz;
    const expected_evfn = ev.evaluateCards;
    const cb = struct {
        fn func(ids: [len]u8, ctx: anytype) !bool {
            var h2 = randomCardSample(len, ctx.map, ctx.rand.random(), 0, 36) catch @panic("error in randomCardSample");

            const rzrank = evfn(&ids);
            ctx.hand_idx += 1;
            const rzrank2 = evfn(&h2);
            const h_alo = Card.cardsToAlo(len, &ids);
            const h2_alo = Card.cardsToAlo(len, &h2);
            var rank = expected_evfn(len, 13, h_alo);
            var rank2 = expected_evfn(len, 13, h2_alo);
            // validate straights and flushes by comparing sorted rank_names
            const strt_flush_categories = &[_]Rank.Category{ .straight_flush, .flush, .straight };
            const rk1_cat = rank.category();
            const rk2_cat = rank2.category();
            const rk1_strt_or_flush = std.mem.indexOfScalar(Rank.Category, strt_flush_categories, rk1_cat) != null;
            const rk2_strt_or_flush = std.mem.indexOfScalar(Rank.Category, strt_flush_categories, rk2_cat) != null;
            if (rk1_strt_or_flush and rk2_strt_or_flush) {
                const h1_winner = ev.cardsToBinary(&h_alo) < ev.cardsToBinary(&h2_alo);
                var buf: [len * 2]u8 = undefined;
                const hand1 = Card.cardsToString(&ids, &buf);
                var rank_names1 = [_]u8{ hand1[0], hand1[2], hand1[4], hand1[6], hand1[8] };
                std.mem.sort(u8, &rank_names1, {}, lessthan_rank_alo);

                std.mem.reverse(u8, &rank_names1);
                var buf2: [len * 2]u8 = undefined;
                const hand2 = Card.cardsToString(&h2, &buf2);
                var rank_names2 = [_]u8{ hand2[0], hand2[2], hand2[4], hand2[6], hand2[8] };
                std.mem.sort(u8, &rank_names2, {}, lessthan_rank_alo);
                std.mem.reverse(u8, &rank_names2);
                const h1_less = asc_alo_hands({}, &rank_names1, &rank_names2);
                if (h1_less != h1_winner)
                    print("h1_less:{} ({s} < {s}) != h1_winner:{} ({b} < {b})", .{
                        h1_less,
                        rank_names1,
                        rank_names2,
                        h1_winner,
                        ev.cardsToBinary(&ids),
                        ev.cardsToBinary(&h2),
                    });

                try std.testing.expectEqual(h1_less, h1_winner);
                return true;
                // skip comparison of strt_flush with non-strt_flush
            } else if (rk1_strt_or_flush or rk2_strt_or_flush)
                return true;

            const both_lte = rzrank.value >= rzrank2.value and rank.value <= rank2.value;
            const both_gte = rzrank.value <= rzrank2.value and rank.value >= rank2.value;

            if (!(both_gte or both_lte)) {
                printDebugInfo("razz", len, &ids, &h2, rank, rank2, rzrank, rzrank2, rk1_cat, rk2_cat, .invalid, .invalid, 0, 0);
                try testing.expect(false);
            }
            return ctx.hand_idx < ctx.max_hand_idx;
        }
    }.func;

    try razzValidate(5, "evaluateCardsRazz", cb);
}

test "validate razz 7" {
    const len = 7;
    const evfn = ev.evaluateCardsRazz;
    const cb = struct {
        fn func(ids: [len]u8, ctx: anytype) !bool {
            const rzrank = evfn(&ids);
            ctx.hand_idx += 1;

            const ContextInner = struct {
                best: u16,
                ids: [len]u8,
            };
            var ctx_inner = ContextInner{ .best = std.math.maxInt(u16), .ids = ids };
            const cb_inner = struct {
                fn func(indices: [5]u8, ctx2: anytype) !bool {
                    var ranks: [5]u8 = undefined;
                    for (indices, 0..) |idx, i| ranks[i] = ctx2.ids[idx];
                    const rank = ev.evaluateCardsRazz(&ranks);
                    ctx2.best = @min(ctx2.best, rank.value);
                    return true;
                }
            }.func;
            try util.comb5Cb(0, len, cb_inner, &ctx_inner);
            try testing.expectEqual(rzrank.value, ctx_inner.best);
            return ctx.hand_idx < ctx.max_hand_idx;
        }
    }.func;

    try razzValidate(7, "evaluateCardsRazz", cb);
}

// test "benchmark 5" {
//     // std.log.warn("benchmark 5\n", .{});
//     try benchmark(5, ev.evaluate5Cards, 13, "evaluate5Cards", testing.io);
// }

// test "benchmark 5 c" {
//     // std.log.warn("benchmark 5 c\n", .{});
//     try benchmark(5, evaluate5CardsC, 13, "evaluate5CardsC", testing.io);
// }

// fn benchmark(N: comptime_int, evfn: anytype, R: comptime_int, comptime evfn_name: []const u8, io: Io) !void {
//     var map = std.AutoHashMap(u8, void).init(std.heap.c_allocator);
//     var ctx = try TestCtx.init(&map, io);
//     defer ctx.map.deinit();
//     try ctx.map.ensureTotalCapacity(N);
//     while (ctx.hand_idx < benchmark_num_trials * 1000) : (ctx.hand_idx += 1) {
//         const cards = try randomCardSample(N, ctx.map, ctx.rand.random(), 0, R * 4);
//         // omaha and shortdeck and razz don't accept num_ranks param
//         const args = if (R != 9) switch (N) { // non-shortdeck
//             5 => switch (@TypeOf(evfn)) {
//                 @TypeOf(ev.evaluate5Shortdeck),
//                 => .{cards},
//                 else => .{ R, cards },
//             },
//             7 => switch (@TypeOf(evfn)) {
//                 @TypeOf(ev.evaluate7Shortdeck),
//                 => .{cards},
//                 else => .{ R, cards },
//             },
//             9 => .{cards},
//             else => return error.InvalidLen,
//         } else switch (N) { // shortdeck
//             5, 7 => .{ R, cards },
//             else => return error.InvalidLen,
//         };
//         const time = Io.Timestamp.now(io, .cpu_process);
//         const rank = @call(.auto, evfn, args);
//         std.mem.doNotOptimizeAway(rank);
//         ctx.total_time.nanoseconds += @intCast(time.untilNow(io, .cpu_process).nanoseconds);
//         if (rank.value == 0) return error.InvalidRank;
//         ctx.hand_idx += 1;
//     }
//     printBencharkInfo(ctx.total_time, ctx.hand_idx, evfn_name);
// }
//
// test "benchmark 7" {
//     // std.log.warn("benchmark 7\n", .{});
//     try benchmark(7, ev.evaluate7Cards, 13, "evaluate7Cards", testing.io);
// }
//
// test "benchmark 7 c" {
//     // std.log.warn("benchmark 7 c\n", .{});
//     try benchmark(7, evaluate7CardsC, 13, "evaluate7CardsC", testing.io);
// }

// test "benchmark omaha" {
//     // std.log.warn("benchmark omaha\n", .{});
//     try benchmark(9, ev.evaluateOmahaCards, 13, "evaluateOmahaCards", testing.io);
// }

// test "benchmark omaha c" {
//     // std.log.warn("benchmark omaha c\n", .{});
//     try benchmark(9, evaluateOmahaCardsC, 13, "evaluateOmahaCardsC", testing.io);
// }
//
// // test "benchmark shortdeck 5" {
//     // std.log.warn("benchmark shortdeck 5\n", .{});
//     try benchmark(5, ev.evaluate5Shortdeck, 9, "evaluateShortdeck5", testing.io);
// }

// test "benchmark shortdeck 7" {
//     // std.log.warn("benchmark shortdeck 7\n", .{});
//     try benchmark(7, ev.evaluate7Shortdeck, 9, "evaluateShortdeck7", testing.io);
// }

// test "benchmark razz 5" {
//     // std.log.warn("benchmark razz 5\n", .{});
//     try benchmark(5, ev.evaluate5CardsRazz, 13, "evaluateRazz5Vec", testing.io);
// }

// test "benchmark razz 7" {
//     // std.log.warn("benchmark razz 7\n", .{});
//     try benchmark(7, ev.evaluate7CardsRazz, 13, "evaluateRazz7Vec", testing.io);
// }

const std = @import("std");
const print = std.debug.print;
const Io = std.Io;

const Card = @import("card.zig");
const Rank = @import("rank.zig");
const ev = @import("evaluator.zig");
const phe_c = struct {
    pub extern fn evaluate_5cards(c_int, c_int, c_int, c_int, c_int) c_int;
    pub extern fn evaluate_7cards(c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
    pub extern fn evaluate_omaha_cards(c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
};
const util = @import("util.zig");
