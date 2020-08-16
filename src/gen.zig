const std = @import("std");
const warn = std.debug.warn;
const Card = @import("card.zig");
const Rank = @import("rank.zig");
const util = @import("util.zig");
const ev = @import("evaluator.zig");
extern const flush: [8192]u16;
extern const noflush5: [6175]u16;
extern const noflush7: [49205]u16;
extern const choose: [53][10]u32;
extern const dp: [5][14][10]u32;
extern const suits: [4609]u8;
pub extern const noflush_omaha: [11238500]u16;
pub extern const flush_omaha: [4099095]u16;

fn output(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut();
    _ = stdout.outStream().print(fmt, args) catch unreachable;
}

const CategoryCount = [std.meta.fields(Rank.Category).len]u32;
const CategoryCountBoundary = [std.meta.fields(Rank.Category).len][2]u32;
const CCDMap = std.StringHashMap(u32);
const CategoryCountDistinct = [std.meta.fields(Rank.Category).len]CCDMap;
const log_verbose = false;
const log_counts = false;
const output_table = true;
const output_comments = false;

// const allocator = std.heap.page_allocator;
const allocator = std.heap.c_allocator;

// zig test src/gen.zig --test-filter gensd5 -lc -L zig-cache/lib -l tables > src/hashtable_sd5.zig
test "gensd5" {
    const T = [5]u6;
    var ctx = .{
        .flushes_sd = std.mem.zeroes([std.math.pow(u16, 2, 9)]u16),
        .nonflushes_sd = std.mem.zeroes([1278]u16),
        .category_counts = @as(CategoryCount, undefined),
        .category_counts_distinct = @as(CategoryCountDistinct, undefined),
        .category_rank_boundaries = @as(CategoryCountBoundary, undefined),
    };

    if (log_counts) {
        ctx.category_counts = std.mem.zeroes(CategoryCount);
        for (ctx.category_counts_distinct) |*ccd| ccd.* = CCDMap.init(allocator);
        ctx.category_rank_boundaries = std.mem.zeroes(CategoryCountBoundary);
        for (ctx.category_rank_boundaries) |*crb| crb[0] = std.math.maxInt(u16);
    }
    defer if (log_counts) for (ctx.category_counts_distinct) |*ccd| ccd.deinit();

    const cb = struct {
        fn func(ids: [5]u6, ctx_: anytype) !bool {
            var cards = Card.cardsFromIds(T.len, &ids);

            var buf: [20]u8 = undefined;
            const hand = Card.cardsToString(&cards, &buf);
            var rank = ev.evaluateCards(&cards, 13);
            var category = rank.category();

            rank.value = switch (rank.value) {
                // 6789A flush
                747 => 10,
                // 6789A straight
                6610 => 1609,
                else => rank.sdAdjusted().value,
            };
            std.debug.assert(rank.value != 0);
            var cards_sd: [5]Card = undefined;
            for (cards_sd) |*c, i| c.id = ids[i] - 16;
            const category_adjusted = rank.category();
            switch (category) {
                .straight_flush, .flush => {
                    const bin_sd = ev.cardsToBinary(&cards_sd);
                    // warn("hand {} bin_sd {b:0<9} {}\n", .{ hand, bin_sd, bin_sd });
                    ctx_.flushes_sd[bin_sd] = rank.value;
                },
                else => {
                    var quinary = [1]u6{0} ** 9;
                    for (cards_sd) |c| quinary[c.id >> 2] += 1;
                    const hash = ev.hashQuinary(&quinary, 9, 5);
                    ctx_.nonflushes_sd[hash] = rank.value;
                },
            }
            // TODO move this logic to function and use in gensd7
            if (log_counts) {
                const catid_adj = category_adjusted.id();
                const catid = category.id();
                category_counts[catid] += 1;
                ctx_.category_rank_boundaries[catid_adj][0] = std.math.min(ctx_.category_rank_boundaries[catid_adj][0], rank.value);
                ctx_.category_rank_boundaries[catid_adj][1] = std.math.max(ctx_.category_rank_boundaries[catid_adj][1], rank.value);
                var quinary = [1]u8{0} ** 9;
                for (cards_sd) |c| quinary[c.id >> 2] += 1;
                const qs = try std.mem.dupe(allocator, u8, &quinary);
                _ = try ctx_.category_counts_distinct[catid].put(qs, if (ctx_.category_counts_distinct[catid].getValue(qs)) |c| c + 1 else 1);
            }
            return true;
        }
    }.func;

    try util.comb5Cb(16, 52, cb, &ctx);

    if (output_table) outputTables(ctx.flushes_sd, ctx.nonflushes_sd, output_comments);
    if (log_counts) warnLogCounts(ctx.category_counts, ctx.category_counts_distinct, ctx.category_rank_boundaries);
}

fn warnLogCounts(category_counts: CategoryCount, category_counts_distinct: CategoryCountDistinct, category_rank_boundaries: CategoryCountBoundary) void {
    warn("total counts\n", .{});
    for (category_counts) |cc, i| {
        warn("cat {} count {}\n", .{ @intToEnum(Rank.Category, @truncate(@TagType(Rank.Category), i)), cc });
    }
    warn("distinct counts\n", .{});
    for (category_counts_distinct) |ccd, i| {
        warn("cat {} count {}\n", .{ @intToEnum(Rank.Category, @truncate(@TagType(Rank.Category), i)), ccd.count() });
    }
    warn("category rank ranges\n", .{});
    for (category_rank_boundaries) |chb, i| {
        const cat = @intToEnum(Rank.Category, @truncate(@TagType(Rank.Category), i));
        if (cat == .invalid) continue;
        warn("cat {} range {}-{}:{}\n", .{ cat, chb[0], chb[1], chb[1] - chb[0] });
    }
}

// zig test src/gen.zig --test-filter gensd7 -lc -L zig-cache/lib -l tables > src/hashtable_sd7.zig
test "gensd7" {
    const T = [7]u6;
    var ctx = .{
        .flushes_sd = std.mem.zeroes([std.math.pow(u16, 2, 9)]u16),
        .nonflushes_sd = std.mem.zeroes([6030]u16),
        .category_counts = @as(CategoryCount, undefined),
        .category_counts_distinct = @as(CategoryCountDistinct, undefined),
    };
    if (log_counts) {
        ctx.category_counts = std.mem.zeroes(CategoryCount);
        for (ctx.category_counts_distinct) |*ccd| ccd.* = CCDMap.init(allocator);
    }
    defer if (log_counts) for (ctx.category_counts_distinct) |*ccd| ccd.deinit();

    const cb = struct {
        fn func(ids: [7]u6, ctx_: anytype) !bool {
            var cards = Card.cardsFromIds(T.len, &ids);

            var buf: [20]u8 = undefined;
            const hand = Card.cardsToString(&cards, &buf);
            var rank = ev.evaluateCards(&cards, 13);
            var category = rank.category();
            rank.value = switch (rank.value) {
                // 6789A flush
                747 => 10,
                else => switch (category) {
                    .flush => rank.value - 156,
                    .full_house => rank.value + 1277,
                    else => blk: {
                        const bin = ev.cardsToBinary(&cards);
                        const wheel_mask = 0b1000011110000;
                        break :blk if (bin & wheel_mask == wheel_mask and @enumToInt(rank.category()) > @enumToInt(@as(Rank.Category, .straight)))
                            1609
                        else
                            rank.value;
                        // warn("found str8 {} rank {} {b}\n", .{ hand, rank.value, bin });
                    },
                },
            };
            std.debug.assert(rank.value != 0);
            var cards_sd: [7]Card = undefined;
            for (cards_sd) |*c, i| c.id = ids[i] - 16;
            const category_adjusted = rank.category();
            switch (category) {
                .straight_flush, .flush => {
                    const bin_sd = ev.cardsToBinary(&cards_sd);
                    // warn("hand {} bin_sd {b:0<9} {}\n", .{ hand, bin_sd, bin_sd });
                    ctx_.flushes_sd[bin_sd] = rank.value;
                },
                else => {
                    var quinary = [1]u6{0} ** 9;
                    for (cards_sd) |c| quinary[c.id >> 2] += 1;
                    const hash = ev.hashQuinary(&quinary, 9, 7);
                    ctx_.nonflushes_sd[hash] = rank.value;
                },
            }
            if (log_counts)
                _ = try ctx_.category_counts_distinct[category.id()].put(binstr, if (ctx_.category_counts_distinct[category.id()].getValue(binstr)) |c| c + 1 else 1);
            return true;
        }
    }.func;

    try util.comb7Cb(16, 52, cb, &ctx);

    if (output_table) outputTables(ctx.flushes_sd, ctx.nonflushes_sd, output_comments);
    if (log_counts) warnLogCounts(ctx.category_counts, ctx.category_counts_distinct, ctx.category_rank_boundaries);
}

fn outputTables(flushes_sd: [512]u16, nonflushes_sd: anytype, output_comments_: bool) void {
    const items_per_line = 10;
    output("pub const flushes = [_]u16{{\n", .{});
    var i: usize = 0;
    while (i < flushes_sd.len) : (i += 1) {
        if (output_comments_) {
            output("{}, // {}\n", .{ flushes_sd[i], i });
        } else {
            var j: usize = i;
            while (j < std.math.min(i + items_per_line, flushes_sd.len)) : (j += 1) {
                output("{}, ", .{flushes_sd[j]});
            }
            i = j - 1;
            output("\n", .{});
        }
    }
    output("}};\n", .{});
    std.debug.assert(i == flushes_sd.len);

    output("pub const nonflushes = [_]u16{{\n", .{});
    i = 0;
    while (i < nonflushes_sd.len) : (i += 1) {
        if (output_comments_) {
            output("{}, // {}\n", .{ nonflushes_sd[i], i });
        } else {
            var j: usize = i;
            while (j < std.math.min(i + items_per_line, nonflushes_sd.len)) : (j += 1) {
                output("{}, ", .{nonflushes_sd[j]});
            }
            output("\n", .{});
            i = j - 1;
        }
    }
    output("}};\n", .{});
    std.debug.assert(i == nonflushes_sd.len);
}

// zig test src/gen.zig --test-filter razzBuildFromExisting -lc -ltables -Lzig-cache/lib -Drelease-fast
// use existing lookup values to create razz quinary hash => rank lookup table
test "razzBuildFromExisting" {
    const gen_table = false;
    const debug = true;

    const filename = "../../go/pokerserver/phe/phe_gen/razzLookup.txt";
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();
    const stream = &file.inStream();
    var buf: [20]u8 = undefined;
    var ranks = [1]u16{0} ** 6162;
    var max: u32 = 0;
    var min: u32 = std.math.maxInt(u32);
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // warn("line {}\n", .{line});
        var parts = std.mem.split(line, ":");
        var hand = [1]u8{'c'} ** 10;
        const ranks_str = parts.next().?;
        for (ranks_str) |card, i| hand[i * 2] = card;
        // warn("hand {}\n", .{hand});
        const cards = Card.cardsToAlo(5, &Card.cardsFromString(5, &hand));
        // const alo_cards = Card.cardsToAlo(5, &cards);
        const rank_str = parts.next().?;
        const rank = try std.fmt.parseUnsigned(u16, rank_str, 10);
        var quinary = [1]u6{0} ** 13;
        for (cards) |card| quinary[card.id >> 2] += 1;
        const hash = ev.hashQuinary(&quinary, 13, 5);
        if (debug)
            warn("{}: {} ({}) ranks '{}' rank_str '{}' \n", .{ hash, rank, hand, ranks_str, rank_str });
        ranks[hash - 1] = rank + 1;
        max = std.math.max(hash, max);
        min = std.math.min(hash, min);
    }
    if (gen_table) {
        // warn("max {} min {}\n", .{ max, min });
        const items_per_line = 10;
        output("pub const razz_lookup5 = [_]u16{{\n", .{});
        var i: usize = 0;
        while (i < ranks.len) : (i += 1) {
            var j: usize = i;
            while (j < std.math.min(i + items_per_line, ranks.len)) : (j += 1) {
                output("{}, ", .{ranks[j]});
            }
            output("\n", .{});
            i = j - 1;
        }
        output("}};\n", .{});
    }
}

const RankInfo = struct {
    rank: u16 = 0,
    rank_names: []const u8 = undefined,
};
const HandsMap = std.StringHashMap(RankInfo);

fn asc_alo_hands(context: void, a: *HandsMap.Entry, b: *HandsMap.Entry) bool {
    for (a.key) |ae, i| {
        const be = b.key[i];
        if (ae == be) continue;
        return lessthan_rank_alo({}, ae, be);
    }
    return false;
}

fn asc_byrank_alo_hands(context: void, a: *HandsMap.Entry, b: *HandsMap.Entry) bool {
    return a.value.rank > b.value.rank;
}

pub fn lessthan_rank_alo(context: void, a: u8, b: u8) bool {
    return Card.rankToAlo(Card.nameToRank(a)) < Card.rankToAlo(Card.nameToRank(b));
}

// zig test src/gen.zig --test-filter razzBuild5 -lc -ltables -Lzig-cache/lib -Drelease-fast > src/hashtable_razz5.zig && zig build test
// create a sorted list of all razz hands
// keep a separate set for each paired hand class
// paired hand classes can be ordered by standard poker alo ev rank
// all hands from non-paired hands classes can be stored in a set
// these can be ordered by alo card rank (A => 0, K => 12)
test "razzBuild5" {
    const len = 5;
    const Ctx = struct {
        fuzz_num_hands: usize = 0,
        non_paired_hands_map: HandsMap = HandsMap.init(allocator),
        onepr_hands_map: HandsMap = HandsMap.init(allocator),
        twopr_hands_map: HandsMap = HandsMap.init(allocator),
        threekind_hands_map: HandsMap = HandsMap.init(allocator),
        fullhouse_hands_map: HandsMap = HandsMap.init(allocator),
        fourkind_hands_map: HandsMap = HandsMap.init(allocator),
    };
    var ctx = Ctx{};

    defer {
        ctx.non_paired_hands_map.deinit();
        ctx.onepr_hands_map.deinit();
        ctx.twopr_hands_map.deinit();
        ctx.threekind_hands_map.deinit();
        ctx.fullhouse_hands_map.deinit();
        ctx.fourkind_hands_map.deinit();
    }
    const cb = struct {
        fn func(ids: [5]u6, ctx_: anytype) !bool {
            const cards = Card.cardsFromIds(len, &ids);
            var rank = ev.evaluate5Cards(cards[0], cards[1], cards[2], cards[3], cards[4], 13);
            const category = rank.category();
            const map_to_use = switch (category) {
                .straight_flush, .flush, .straight, .high_card => &ctx_.non_paired_hands_map,
                .one_pair => &ctx_.onepr_hands_map,
                .two_pair => &ctx_.twopr_hands_map,
                .three_of_a_kind => &ctx_.threekind_hands_map,
                .full_house => &ctx_.fullhouse_hands_map,
                .four_of_a_kind => &ctx_.fourkind_hands_map,
                else => std.debug.panic("invalid category {}\n", .{category}),
            };
            var buf: [10]u8 = undefined;
            const hand = Card.cardsToString(&cards, &buf);
            var rank_names = [_]u8{ hand[0], hand[2], hand[4], hand[6], hand[8] };
            if (std.mem.indexOfScalar(Rank.Category, &[_]Rank.Category{ .straight_flush, .flush, .straight, .high_card }, category) != null) {
                std.sort.sort(u8, &rank_names, {}, lessthan_rank_alo);
                std.mem.reverse(u8, &rank_names);
            } else {
                const cards_alo = Card.cardsToAlo(5, &cards);
                rank = ev.evaluate5Cards(cards_alo[0], cards_alo[1], cards_alo[2], cards_alo[3], cards_alo[4], 13);
            }
            const hr = try std.mem.dupe(allocator, u8, &rank_names);
            _ = try map_to_use.put(hr, .{ .rank = rank.value, .rank_names = hr });
            ctx_.fuzz_num_hands += 1;
            return true;
        }
    }.func;

    try util.comb5Cb(0, 52, cb, &ctx);
    var ranks = [1]RankInfo{.{}} ** 6175;
    const hands_maps = [_]*HandsMap{ &ctx.non_paired_hands_map, &ctx.onepr_hands_map, &ctx.twopr_hands_map, &ctx.threekind_hands_map, &ctx.fullhouse_hands_map, &ctx.fourkind_hands_map };
    // warn("non_paired_hands_map count {}", .{non_paired_hands_map.count()});
    var hand_rank: u16 = 0;
    for (hands_maps) |hands_map| {
        // output("// hands_map count {}\n", .{hands_map.count()});
        var hands_list = std.ArrayList(*HandsMap.Entry).init(allocator);
        defer hands_list.deinit();
        var it = hands_map.iterator();
        while (it.next()) |kv| _ = try hands_list.append(kv);
        if (hands_map == &ctx.non_paired_hands_map) {
            // output("// non_paired_hands_map\n", .{});
            std.sort.sort(*HandsMap.Entry, hands_list.items, {}, asc_alo_hands);
        } else
            std.sort.sort(*HandsMap.Entry, hands_list.items, {}, asc_byrank_alo_hands);

        for (hands_list.items) |entry, i| {
            // output("{}, // {}\n", .{ hand_rank, entry.key });
            hand_rank += 1;
            var quinary = [1]u6{0} ** 13;
            for (entry.key) |r|
                quinary[Card.rankToAlo(Card.nameToRank(r))] += 1;
            const hash = ev.hashQuinary(&quinary, 13, 5);
            std.testing.expectEqual(ranks[hash].rank, 0);
            ranks[hash] = .{ .rank = hand_rank, .rank_names = entry.key };
        }
    }
    const items_per_line = 10;
    var current_map = ctx.non_paired_hands_map;
    var current_map_i: u16 = 0;
    output("pub const razz_lookup5 = [_]u16 {{\n", .{});
    var i: usize = 0;
    while (i < ranks.len) : (i += 1) {
        if (output_comments) {
            output("{}, // {}\n", .{ ranks[i].rank, ranks[i].rank_names });
        } else {
            var j: usize = i;
            while (j < std.math.min(i + items_per_line, ranks.len)) : (j += 1) {
                output("{}, ", .{ranks[j].rank});
            }
            output("\n", .{});
            i = j - 1;
        }
    }
    output("}};\n", .{});
}

// zig test src/gen.zig --test-filter razzBuild7 -ltables -Lzig-cache/lib -Drelease-fast > src/hashtable_razz7.zig
test "razzBuild7" {
    const len = 7;
    var fuzz_num_hands: usize = 0;
    const max_num_hands = 300;
    // var ranks = [1]RankInfo{.{}} ** 6175;
    var ranks = [1]u16{0} ** 49205;
    const hashtable_razz5 = @import("hashtable_razz5.zig");

    const ContextInner = struct {
        best: u16,
        ids: [7]u6,
    };
    const cb_inner = struct {
        fn func(indices: [5]u6, ctx: anytype) !bool {
            var ids: [5]u6 = undefined;
            for (indices) |idx, i| ids[i] = ctx.ids[idx];
            const rank = ev.evaluateCardsRazz(&Card.cardsFromIds(5, &ids));
            ctx.best = std.math.min(ctx.best, rank.value);
            return true;
        }
    }.func;

    const Context = struct {
        ranks: @TypeOf(ranks),
    };
    const cb = struct {
        fn func(ids: [7]u6, ctx: anytype) !bool {
            var ctx_inner = ContextInner{ .best = std.math.maxInt(u16), .ids = ids };
            try util.comb5Cb(0, 7, cb_inner, &ctx_inner);
            var quinary = [1]u6{0} ** 13;
            for (ids) |id|
                quinary[Card.rankToAlo(id >> 2)] += 1;
            const hash = ev.hashQuinary(&quinary, 13, 7);

            ctx.ranks[hash] = ctx_inner.best;
            return true;
        }
    }.func;
    var ctx = Context{
        .ranks = ranks,
    };

    try util.comb7Cb(0, 52, cb, &ctx);

    const items_per_line = 10;
    output("pub const razz_lookup7 = [_]u16 {{\n", .{});
    var i: usize = 0;
    while (i < ctx.ranks.len) : (i += 1) {
        if (output_comments) {
            output("{}, // {}\n", .{ctx.ranks[i]});
        } else {
            var j: usize = i;
            while (j < std.math.min(i + items_per_line, ctx.ranks.len)) : (j += 1) {
                output("{}, ", .{ctx.ranks[j]});
            }
            output("\n", .{});
            i = j - 1;
        }
    }
    output("}};\n", .{});
}
