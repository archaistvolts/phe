test "fuzz" {
    const Context = struct {
        fn testOne(_: @This(), smith: *testing.Smith) anyerror!void {
            try pheOracle(testing.allocator, smith);
        }
    };
    try testing.fuzz(Context{}, Context.testOne, .{}); // TODO create corpus.zon file test "holdem" and use here
}

fn pheOracle(_: mem.Allocator, smith: *testing.Smith) !void {
    const ncards = smith.valueWeighted(u8, &.{
        .{ .min = 5, .max = 5, .weight = 50 },
        .{ .min = 7, .max = 7, .weight = 50 },
    });
    const deck = smith.value(ev.Deck);

    var buf: [14]u8 = undefined;
    switch (ncards) {
        inline 5, 7 => |N| switch (deck) {
            inline .short, .full => |R| {
                const h1 = buf[0..N];
                const h2 = buf[N .. N * 2];
                CombinationIterator(@backingInt(R) * 4, N * 2).randomHand(smith, buf[0 .. N * 2]);
                const a1 = ev.evaluateNCards(N, R, h1.*);
                const a2 = ev.evaluateNCards(N, R, h2.*);
                const e1, const e2 = if (R == .short)
                    .{ phe.evaluateCardsShortdeck(h1), phe.evaluateCardsShortdeck(h2) }
                else
                    .{ phe.evaluateCards(N, @backingInt(R), h1.*), phe.evaluateCards(N, @backingInt(R), h2.*) };
                errdefer std.debug.print("N R: {} {t}\nh1: {f} {f}\nh2: {f} {f}\ne1 e2: {} {}\na1 a2: {f} {f}\n", .{
                    N,
                    R,
                    Cards.fromIds(R, h1).fmtColor(),
                    Cards.fromIds(R, h1),
                    Cards.fromIds(R, h2).fmtColor(),
                    Cards.fromIds(R, h2),
                    e1.value,
                    e2.value,
                    a1,
                    a2,
                });
                if ((a1.category == .straight_flush_shortdeck and a1.hi == 1) or
                    (a2.category == .straight_flush_shortdeck and a2.hi == 1))
                {
                    // known oracle incorrect rank for wheel
                    try testing.expectEqual(e1.value < e2.value, a1.int() < a2.int());
                } else {
                    try testing.expectEqual(e1.value > e2.value, a1.int() < a2.int());
                }
            },
        },
        else => unreachable,
    }
}

fn pheFuzzFile(io: Io, path: []const u8) !void {
    const contents = Io.Dir.cwd().readFileAlloc(io, path, testing.allocator, .unlimited) catch return;
    defer testing.allocator.free(contents);
    var smith = testing.Smith{ .in = contents };
    try pheOracle(testing.allocator, &smith);
}

test "crash - current" {
    try pheFuzzFile(testing.io, ".zig-cache/f/crash");
}

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

// compare against phe_c
test "validate 5" {
    if (options.run_slow_tests) {
        const cb = struct {
            fn func(ids: [5]u8, ctx: *[5]u8) !bool {
                const a1 = ev.evaluateNCards(5, .full, ids);
                const a2 = ev.evaluateNCards(5, .full, ctx.*);
                const e1 = phe.evaluate5Cards(ids);
                const e2 = phe.evaluate5cards(ctx);
                errdefer std.debug.print("{f}\n{f}\n{} {} {} {}\n", .{ Cards.fromIds(.full, &ids), Cards.fromIds(.full, ctx), a1, a2, e1.value, e2.value });
                try testing.expectEqual(a1 > a2, e1 < e2);
                ctx.* = ids;
                return true;
            }
        }.func;
        var prev: [5]u8 = std.simd.iota(u8, 5);
        try util.comb5Cb(0, 52, cb, &prev);
    }
    var prng = std.Random.DefaultPrng.init(@intCast(Io.Timestamp.now(testing.io, .cpu_process).nanoseconds));
    const random = prng.random();
    var ids: [10]u8 = undefined;
    for (0..10_000) |_| {
        CombinationIterator(52, 10).randomHand(random, &ids);
        const a1 = ev.evaluateNCards(5, .full, ids[0..5].*);
        const a2 = ev.evaluateNCards(5, .full, ids[5..10].*);
        const e1 = phe.evaluate5Cards(13, ids[0..5].*);
        const e2 = phe.evaluate5Cards(13, ids[5..10].*);
        errdefer std.debug.print("{f}\n{f}\n{} {} {} {}\n", .{ Cards.fromIds(.full, ids[0..5]), Cards.fromIds(.full, ids[5..10]), a1, a2, e1.value, e2.value });
        try testing.expectEqual(e1.value < e2.value, a1.int() > a2.int());
    }
}

test "validate 7" {
    if (options.run_slow_tests) {
        const cb = struct {
            fn func(ids: [7]u8, ctx: *[7]u8) !bool {
                const a1 = ev.evaluateNCards(7, .full, ids);
                const a2 = ev.evaluateNCards(7, .full, ctx.*);
                const e1 = phe.evaluate7Cards(13, ids[0..7].*);
                const e2 = phe.evaluate7Cards(13, ctx[0..7].*);
                errdefer std.debug.print("{f}\n{f}\n{} {} {} {}\n", .{ Cards.fromIds(.full, ids[0..7]), Cards.fromIds(.full, ctx[0..7]), a1, a2, e1.value, e2.value });
                try testing.expectEqual(e1 < e2, a1.int() > a2.int());
                ctx.* = ids;
                return true;
            }
        }.func;
        var prev: [7]u8 = std.simd.iota(u8, 7);
        try util.comb7Cb(0, 52, cb, &prev);
    }

    var prng = std.Random.DefaultPrng.init(@intCast(Io.Timestamp.now(testing.io, .cpu_process).nanoseconds));
    const random = prng.random();
    var ids: [14]u8 = undefined;
    for (0..10_000) |_| {
        CombinationIterator(52, 14).randomHand(random, &ids);
        const a1 = ev.evaluateNCards(7, .full, ids[0..7].*);
        const a2 = ev.evaluateNCards(7, .full, ids[7..14].*);
        const e1 = phe.evaluate7Cards(13, ids[0..7].*);
        const e2 = phe.evaluate7Cards(13, ids[7..14].*);
        errdefer std.debug.print("{f}\n{f}\n{} {} {} {}\n", .{ Cards.fromIds(.full, ids[0..7]), Cards.fromIds(.full, ids[7..14]), a1, a2, e1.value, e2.value });
        try testing.expectEqual(e1.value < e2.value, a1.int() > a2.int());
    }
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

fn evaluateOmahaCardsC(N: comptime_int, R: comptime_int, cs: [9]u8) u32 {
    _ = N;
    _ = R;
    return phe.evaluateOmahaCards(cs);
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

    try checkRankOrder(.full, hi_seven, hi_ace, "", .lt);
    try checkRankOrder(.full, hi_ace, pr, "", .lt);
    try checkRankOrder(.full, pr, pr2, "", .lt);
    try checkRankOrder(.full, pr2, pr3, "", .lt);
    try checkRankOrder(.full, pr3, pr4, "", .lt);
    try checkRankOrder(.full, pr4, pr5, "", .lt);
    try checkRankOrder(.full, pr5, pr6, "", .lt);
    try checkRankOrder(.full, pr6, pr7, "", .lt);
    try checkRankOrder(.full, pr6, two_pr1, "", .lt);
    try checkRankOrder(.full, two_pr1, two_pr2, "", .lt);
    try checkRankOrder(.full, two_pr2, two_pr3, "", .lt);
    try checkRankOrder(.full, two_pr3, three_kind1, "", .lt);
    try checkRankOrder(.full, three_kind1, three_kind2, "", .lt);
    try checkRankOrder(.full, three_kind2, three_kind3, "", .lt);
    try checkRankOrder(.full, three_kind3, straight_wheel, "", .lt);
    try checkRankOrder(.full, straight_wheel, straight, "", .lt);
    try checkRankOrder(.full, straight, straight_broadway, "", .lt);
    try checkRankOrder(.full, straight_broadway, flush0, "", .lt);
    try checkRankOrder(.full, flush0, flush_k_hi, "", .lt);
    try checkRankOrder(.full, flush_k_hi, flush_a_hi, "", .lt);
    try checkRankOrder(.full, flush_a_hi, full_house1, "", .lt);
    try checkRankOrder(.full, full_house1, full_house2, "", .lt);
    try checkRankOrder(.full, full_house2, four_kind1, "", .lt);
    try checkRankOrder(.full, four_kind1, four_kind2, "", .lt);
    try checkRankOrder(.full, four_kind2, four_kind3, "", .lt);
    try checkRankOrder(.full, four_kind3, strt_flush_wheel, "", .lt);
    try checkRankOrder(.full, strt_flush_wheel, strt_flush1, "", .lt);
    try checkRankOrder(.full, strt_flush1, strt_flush_royal, "", .lt);
    try checkRankOrder(.full, strt_flush1, strt_flush_royal, "", .lt);

    try checkRankOrder(.full, hh2, hh1, ajq23_b, .lt);
    try checkRankOrder(.full, hh3, hh2, ajq23_b, .lt);
    try checkRankOrder(.full, hh4, hh3, ajq23_b, .lt);

    // misc validation failures
    try checkRankOrder(.full, "5c6c7c8d8s", "5c6c7c8d9c", "", .lt);
    try checkRankOrder(.full, "2c2d3c4c5c6c8c", "2c2d3c4c5c6c7s", "", .eq);
    try checkRankOrder(.full, "2c2d3d4d5d6d7c", "2c2d3d4d5d6d6s", "", .eq);
    try checkRankOrder(.full, "2c2d3c4c5c6cAc", "2c2d3c4c5c6cKs", "", .eq);
    try checkRankOrder(.full, "2c2d3c4c5d6dAc", "2c2d3c4c5d6dKs", "", .eq);
    try checkRankOrder(.full, "2c3c4c5c6c7cAd", "2c3c4c5c6c7cAc", "", .eq);
    try checkRankOrder(.full, "2c3c4c5c6c7d8c", "2c3c4c5c6c7d7s", "", .eq);
    try checkRankOrder(.full, "2c9cTcJcQcKcKs", "2c9cTcJcQcKcAc", "", .lt);
    try checkRankOrder(.full, "2c2s3s4s5s6dAs", "2c2s3s4s5s6h6s", "", .lt);
    try checkRankOrder(.full, "Jd5sKd8dAcQs6c", "AhJcKcQh3d8c7h", "", .eq);
    try checkRankOrder(.full, "Qh7cJsAd7sKc2d", "7dQd7hKhAhTd3c", "", .eq);
    try checkRankOrder(.full, "2c2d2h2s3c3d3s", "2c2d2h2s3c3d4c", "", .lt);
    try checkRankOrder(.full, "2c2d3c3d4c4d5s", "2c2d3c3d4c4d6c", "", .lt);
    try checkRankOrder(.full, "QhQdKd5d7h5hKs", "6hKhQsJsKc2cQc", "", .lt);
    try checkRankOrder(.full, "Js4s2s7s3s6hKs", "As4dKd7d3d7hJd", "", .eq);
    try checkRankOrder(.full, "2c2d2h3c5d", "2c2d2h4c5c", "", .lt);
    try checkRankOrder(.full, "2c2d2h3c5d", "2c2d2h4c5c", "", .lt);
    try checkRankOrder(.full, "5dAcAd9dKd7d8d", "9sAsKs2s7s4s8s", "", .eq);
    try checkRankOrder(.full, "Kd8d7d5d6d", "As8s7s4s5s", "", .lt);
}

fn checkRankOrder(comptime R: ev.Deck, comptime l: []const u8, comptime r: []const u8, comptime b: []const u8, order: std.math.Order) !void {
    const lf = b ++ l;
    const rf = b ++ r;
    comptime assert(lf.len == rf.len);
    const N = lf.len / 2;
    const lr = ev.evaluateNHand(N, R, lf);
    const rr = ev.evaluateNHand(N, R, rf);
    errdefer {
        var lids: [N]u8 = undefined;
        var rids: [N]u8 = undefined;
        Cards.idsFromNames(R, lf, &lids);
        Cards.idsFromNames(R, rf, &rids);
        std.debug.print(
            "low:  {f} {f}\nhigh: {f} {f}\n",
            .{ Cards.fromIds(R, &lids).fmtColor(), lr, Cards.fromIds(R, &rids).fmtColor(), rr },
        );
    }
    try testing.expectEqual(order, std.math.order(lr.int(), rr.int()));
}

test "omaha ranks" {
    if (true) return error.SkipZigTest;
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
    try isRankClassOh(.three_kind, oh6, two_pr_b);

    // omaha lo tests
    try islessRkOmaha(oh10, oh9, lo_b2, .lo);
    try islessRkOmaha(oh6, oh10, lo_b2, .lo);
    try islessRkOmaha(oh6, oh10, lo_b, .lo);
    // try isRankClassOh(.two_pair, oh7, lo_b);
    // try isRankClassOh(.two_pair, oh8, lo_b);
}

fn islessRkOmaha(
    comptime l: []const u8,
    comptime h: []const u8,
    comptime board: []const u8,
    comptime hilo: enum { hi, lo },
) !void {
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
        const r2 = phe.evaluateOmahaCards(@as(c_int, @intCast(cards[0].id)), @as(c_int, @intCast(cards[1].id)), @as(c_int, @intCast(cards[2].id)), @as(c_int, @intCast(cards[3].id)), @as(c_int, @intCast(cards[4].id)), @as(c_int, @intCast(cards[5].id)), @as(c_int, @intCast(cards[6].id)), @as(c_int, @intCast(cards[7].id)), @as(c_int, @intCast(cards[8].id)));
        const rc2 = Rank{ .value = @as(u16, @intCast(r2)) };
        std.debug.print(
            "expected {s} but got {s} hand {s} board {s}. c rank class: {}",
            .{ cd, rcd, h, board, rc2.category() },
        );
        try testing.expect(rc == c);
    }
}

inline fn makeFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res: [ranks.len * 2]u8 = @splat('s');
    for (ranks, 0..) |rk, i| res[i * 2] = rk;
    return res;
}

inline fn makeNonFlush(comptime ranks: []const u8) [ranks.len * 2]u8 {
    var res: [ranks.len * 2]u8 = @splat('s');
    for (ranks, 0..) |rk, i| {
        if (i & 1 == 1) res[i * 2 + 1] = 'h';
        res[i * 2] = rk;
    }
    return res;
}

test "shortdeck" {
    try testing.expectEqual(.high_card_shortdeck, ev.evaluateNHand(5, .short, &makeNonFlush("6789J")).category);
    try checkRankOrder(.short, &makeNonFlush("66677"), &makeFlush("6789J"), "", .lt);
    try checkRankOrder(.short, "Ks9hQdJd9sAc8c", "9cAd8h9d7d6hJc", "", .lt);
    try checkRankOrder(.short, "Qs9hKdJd9sAc8c", "9cAd8h9d7d6hJc", "", .lt);
    try checkRankOrder(.short, "Jd8d6dKsAd9dKd", "6s7s8sAsJs9s9c", "", .lt);
    try checkRankOrder(.short, "6d8dQdKsAd9dKd", "6s7s8sAsJs9s9c", "", .lt);
    try checkRankOrder(.short, "6dTdAdQd8d9d7d", "7s6s8sAsKs9s8c", "", .lt);
}

fn printDebugInfo(comptime ev_name: []const u8, len: usize, h: []Card, h2: []Card, rank: Rank, rank2: Rank, rank_sd: Rank, rank_sd2: Rank, cat: Rank.Category, cat2: Rank.Category, sdcat: Rank.Category, sd2cat: Rank.Category, bin: u16, bin2: u16) void {
    var buf: [20]u8 = undefined;
    var buf2: [20]u8 = undefined;
    const cardsToSFn = if (comptime mem.eql(u8, ev_name, "sd")) Card.cardsToStringSd else Card.cardsToString;
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
            var h = Card.cardsFromIds(len, &ids);
            var h2 = randomCardSample(len, ctx.map, ctx.rand.random(), 0, 36) catch @panic("error in randomCardSample");

            const sdrank = if (len == 5) ev.evaluate5Shortdeck(h[0], h[1], h[2], h[3], h[4]) else ev.evaluate7Shortdeck(h[0], h[1], h[2], h[3], h[4], h[5], h[6]);
            const sdrank2 = if (len == 5) ev.evaluate5Shortdeck(h2[0], h2[1], h2[2], h2[3], h2[4]) else ev.evaluate7Shortdeck(h2[0], h2[1], h2[2], h2[3], h2[4], h2[5], h2[6]);

            const rank = if (len == 5) ev.evaluate5Cards(h[0], h[1], h[2], h[3], h[4], 13) else ev.evaluate7Cards(h[0], h[1], h[2], h[3], h[4], h[5], h[6], 13);
            const rank2 = if (len == 5) ev.evaluate5Cards(h2[0], h2[1], h2[2], h2[3], h2[4], 13) else ev.evaluate7Cards(h2[0], h2[1], h2[2], h2[3], h2[4], h2[5], h2[6], 13);

            const sdcat = sdrank.categoryToSd();
            const sdcat2 = sdrank2.categoryToSd();
            const cat = rank.category();
            const cat2 = rank2.category();

            var classes = [_]Rank.Category{ sdcat, sdcat2, cat, cat2 };
            // fail on any invalid ranks
            if (mem.indexOfScalar(Rank.Category, &classes, .invalid)) |_| try testing.expect(false);
            const both_lte = sdrank.value <= sdrank2.value and rank.value <= rank2.value;
            const both_gte = sdrank.value >= sdrank2.value and rank.value >= rank2.value;
            if (!(both_gte or both_lte)) {
                const bin = ev.cardsToBinary(&h);
                const bin2 = ev.cardsToBinary(&h2);
                const wheel_mask = 0b100001111;
                const h_is_wheel = bin & wheel_mask == wheel_mask;
                const h2_is_wheel = bin2 & wheel_mask == wheel_mask;
                if (h_is_wheel or h2_is_wheel) {
                    if (h_is_wheel) {
                        const expected = sdcat == .straight or sdcat == .straight_flush;
                        if (sdcat == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                        else if (!expected) {
                            printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                            try testing.expect(expected);
                        }
                    }
                    if (h2_is_wheel) {
                        const expected = sdcat2 == .straight or sdcat2 == .straight_flush;
                        if (sdcat2 == .flush) {} // possible to have straight and flush but not straight flush w/ 7 cards
                        else if (!expected) {
                            printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                            try testing.expect(expected);
                        }
                    }
                } else if (mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .flush, .full_house, .flush, .full_house })) {
                    const expected = sdrank.value < sdrank2.value and rank.value > rank2.value;
                    if (!expected) {
                        printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        try testing.expect(expected);
                    }
                } else if (mem.eql(Rank.Category, &classes, &[_]Rank.Category{ .full_house, .flush, .full_house, .flush })) {
                    const expected = sdrank.value > sdrank2.value and rank.value < rank2.value;
                    if (!expected) {
                        printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
                        try testing.expect(expected);
                    }
                } else {
                    printDebugInfo("sd", len, &h, &h2, rank, rank2, sdrank, sdrank2, cat, cat2, sdcat, sdcat2, bin, bin2);
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
    if (true) return error.SkipZigTest;
    try sdTest(5, "evaluateShortdeck");
}

test "fuzz shortdeck7" {
    if (true) return error.SkipZigTest;
    try sdTest(7, "evaluateShortdeck");
}

test "razz ev5" {
    if (true) return error.SkipZigTest;
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
            // print("h {}-{} h_prev {}-{}\n", .{ h, r.value, hands[i - 1], r_prevhcb.value });
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

test "validate razz 5" {
    if (true) return error.SkipZigTest;
    const len = 5;
    const evfn = ev.evaluateCardsRazz;
    const expected_evfn = ev.evaluateCards;
    const cb = struct {
        fn func(ids: [len]u8, ctx: anytype) !bool {
            var h = Card.cardsFromIds(len, &ids);
            var h2 = randomCardSample(len, ctx.map, ctx.rand.random(), 0, 36) catch @panic("error in randomCardSample");

            const rzrank = evfn(&h);
            ctx.hand_idx += 1;
            const rzrank2 = evfn(&h2);
            const h_alo = Card.cardsToAlo(len, &h);
            const h2_alo = Card.cardsToAlo(len, &h2);
            var rank = expected_evfn(&h_alo, 13);
            var rank2 = expected_evfn(&h2_alo, 13);
            // validate straights and flushes by comparing sorted rank_names
            const strt_flush_categories = &[_]Rank.Category{ .straight_flush, .flush, .straight };
            const rk1_cat = rank.category();
            const rk2_cat = rank2.category();
            const rk1_strt_or_flush = mem.indexOfScalar(Rank.Category, strt_flush_categories, rk1_cat) != null;
            const rk2_strt_or_flush = mem.indexOfScalar(Rank.Category, strt_flush_categories, rk2_cat) != null;
            if (rk1_strt_or_flush and rk2_strt_or_flush) {
                const h1_winner = ev.cardsToBinary(&h_alo) < ev.cardsToBinary(&h2_alo);
                var buf: [len * 2]u8 = undefined;
                const hand1 = Card.cardsToString(&h, &buf);
                var rank_names1 = [_]u8{ hand1[0], hand1[2], hand1[4], hand1[6], hand1[8] };
                const S = struct {};
                mem.sort(u8, &rank_names1, {}, S.lessthan_rank_alo);

                mem.reverse(u8, &rank_names1);
                var buf2: [len * 2]u8 = undefined;
                const hand2 = Card.cardsToString(&h2, &buf2);
                var rank_names2 = [_]u8{ hand2[0], hand2[2], hand2[4], hand2[6], hand2[8] };
                mem.sort(u8, &rank_names2, {}, S.lessthan_rank_alo);
                mem.reverse(u8, &rank_names2);
                const h1_less = S.asc_alo_hands({}, &rank_names1, &rank_names2);
                if (h1_less != h1_winner)
                    std.debug.print("h1_less:{} ({s} < {s}) != h1_winner:{} ({b} < {b})", .{
                        h1_less,
                        rank_names1,
                        rank_names2,
                        h1_winner,
                        ev.cardsToBinary(&h),
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
                printDebugInfo("razz", len, &h, &h2, rank, rank2, rzrank, rzrank2, rk1_cat, rk2_cat, .invalid, .invalid, 0, 0);
                try testing.expect(false);
            }
            return ctx.hand_idx < ctx.max_hand_idx;
        }
    }.func;

    try razzValidate(5, "evaluateCardsRazz", cb);
}

test "validate razz 7" {
    if (true) return error.SkipZigTest;
    const len = 7;
    const evfn = ev.evaluateCardsRazz;
    const cb = struct {
        fn func(ids: [len]u8, ctx: anytype) !bool {
            var h = Card.cardsFromIds(len, &ids);

            const rzrank = evfn(&h);
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
                    const rank = ev.evaluateCardsRazz(&Card.cardsFromIds(5, &ranks));
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

fn evaluate5CardsRazzVecWrap(a: Card, b: Card, c: Card, d: Card, e: Card, _: usize) Rank {
    return ev.evaluate5CardsRazz(a, b, c, d, e);
}

const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const math = std.math;
const ev = @import("evaluator");
const Card = ev.Card;
const Cards = ev.Cards;
const Rank = ev.Rank;
const util = ev.util;
const assert = std.debug.assert;
const phe = @import("phe");
const CombinationIterator = @import("combinations.zig").CombinationIterator;
const options = @import("build-options");
