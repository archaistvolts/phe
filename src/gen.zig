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

fn output(comptime fmt: []const u8, args: var) void {
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

const allocator = std.heap.page_allocator;

// zig test src/gen.zig --test-evented-io --test-filter gensd5 -lc -L zig-cache/lib -l tables > src/hashtable_sd5.zig
test "gensd5" {
    const T = [5]u6;
    var ch: std.event.Channel(?T) = undefined;
    ch.init(&[_]?T{});
    _ = async util.comb5(16, 52, &ch);
    var flushes_sd = std.mem.zeroes([std.math.pow(u16, 2, 9)]u16);
    var nonflushes_sd = std.mem.zeroes([1278]u16);
    var category_counts: CategoryCount = undefined;
    var category_counts_distinct: CategoryCountDistinct = undefined;
    var category_rank_boundaries: CategoryCountBoundary = undefined;

    if (log_counts) {
        category_counts = std.mem.zeroes(CategoryCount);
        for (category_counts_distinct) |*ccd| ccd.* = CCDMap.init(allocator);
        category_rank_boundaries = std.mem.zeroes(CategoryCountBoundary);
        for (category_rank_boundaries) |*crb| crb[0] = std.math.maxInt(u16);
    }
    defer if (log_counts) for (category_counts_distinct) |*ccd| ccd.deinit();

    while (ch.get()) |ids| {
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
                flushes_sd[bin_sd] = rank.value;
            },
            else => {
                var quinary = [1]u6{0} ** 9;
                for (cards_sd) |c| quinary[c.id >> 2] += 1;
                const hash = ev.hashQuinary(&quinary, 9, 5);
                nonflushes_sd[hash] = rank.value;
            },
        }
        // TODO move this logic to function and use in gensd7
        if (log_counts) {
            const catid_adj = category_adjusted.id();
            const catid = category.id();
            category_counts[catid] += 1;
            category_rank_boundaries[catid_adj][0] = std.math.min(category_rank_boundaries[catid_adj][0], rank.value);
            category_rank_boundaries[catid_adj][1] = std.math.max(category_rank_boundaries[catid_adj][1], rank.value);
            var quinary = [1]u8{0} ** 9;
            for (cards_sd) |c| quinary[c.id >> 2] += 1;
            const qs = try std.mem.dupe(allocator, u8, &quinary);
            _ = try category_counts_distinct[catid].put(qs, if (category_counts_distinct[catid].getValue(qs)) |c| c + 1 else 1);
        }
    }

    if (output_table) outputTables(flushes_sd, nonflushes_sd, output_comments);
    if (log_counts) warnLogCounts(category_counts, category_counts_distinct, category_rank_boundaries);
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

// zig test src/gen.zig --test-evented-io --test-filter gensd7 -lc -L zig-cache/lib -l tables > src/hashtable_sd7.zig
test "gensd7" {
    const T = [7]u6;
    var ch: std.event.Channel(?T) = undefined;
    ch.init(&[_]?T{});
    _ = async util.comb7(16, 52, &ch);
    var flushes_sd = std.mem.zeroes([std.math.pow(u16, 2, 9)]u16);
    var nonflushes_sd = std.mem.zeroes([6030]u16);
    var category_counts: CategoryCount = undefined;
    var category_counts_distinct: CategoryCountDistinct = undefined;
    if (log_counts) {
        category_counts = std.mem.zeroes(CategoryCount);
        for (category_counts_distinct) |*ccd| ccd.* = CCDMap.init(allocator);
    }
    defer if (log_counts) for (category_counts_distinct) |*ccd| ccd.deinit();

    while (ch.get()) |ids| {
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
                flushes_sd[bin_sd] = rank.value;
            },
            else => {
                var quinary = [1]u6{0} ** 9;
                for (cards_sd) |c| quinary[c.id >> 2] += 1;
                const hash = ev.hashQuinary(&quinary, 9, 7);
                nonflushes_sd[hash] = rank.value;
            },
        }
        if (log_counts)
            _ = try category_counts_distinct[category.id()].put(binstr, if (category_counts_distinct[category.id()].getValue(binstr)) |c| c + 1 else 1);
    }

    if (output_table) outputTables(flushes_sd, nonflushes_sd, output_comments);
    if (log_counts) warnLogCounts(category_counts, category_counts_distinct, category_rank_boundaries);
}

fn outputTables(flushes_sd: [512]u16, nonflushes_sd: var, output_comments_: bool) void {
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
