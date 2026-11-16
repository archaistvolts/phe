//! # Resources
//!
//! https://jonathanhsiao.com/blog/evaluating-poker-hands-with-bit-math
//! https://github.com/zekyll/OMPEval
//! https://github.com/eljefeo/dead-horse-eval/
//! https://github.com/kennethshackleton/SKPokerEval
//!

pub const Rank = packed struct(u32) {
    lo: u13,
    hi: u13,
    category: Category,
    _30: u2 = 0,

    pub const uninit: Rank = @fromBackingInt(0);

    pub fn init(category: Category, hi: u13, lo: u13) Rank {
        return .{ .category = category, .hi = hi, .lo = lo };
    }

    pub fn int(r: Rank) u32 {
        return @backingInt(r);
    }

    pub fn fromInt(i: u32) Rank {
        return @fromBackingInt(i);
    }

    pub fn format(r: Rank, w: *Io.Writer) !void {
        try w.print("{t}:{b:0>13}:{b:0>13} {b:0>32}", .{ r.category, r.hi, r.lo, @as(u32, @backingInt(r)) });
    }
};

pub const Category = enum(u4) {
    invalid,
    high_card,
    one_pair,
    two_pair,
    three_kind,
    straight,
    flush,
    full_house,
    four_kind,
    straight_flush,

    pub fn int(cat: Category) u8 {
        return @backingInt(cat);
    }

    pub fn describe(cat: Category) []const u8 {
        return descriptions[cat.id()];
    }

    const descriptions = [_][]const u8{
        "Invalid",
        "High Card",
        "One Pair",
        "Two Pair",
        "Three of a Kind",
        "Straight",
        "Flush",
        "Full House",
        "Four of a Kind",
        "Straight Flush",
    };
};

/// R is the number of ranks, usually 13.
pub fn evaluateNHand(N: comptime_int, R: comptime_int, hand: []const u8) u32 {
    assert(hand.len == N * 2);
    var ids: [N]u8 = undefined;
    const names: []const [2]u8 = @ptrCast(hand);
    for (&ids, names) |*card, name|
        card.* = Card.fromName(&name);
    return evaluateNCards(N, R, ids);
}

/// R is the number of ranks, usually 13.
pub noinline fn evaluateNCards(N: comptime_int, R: comptime_int, cards: [N]u8) u32 {
    const u8xN = @Vector(N, u8);
    const uN = @Int(.unsigned, N);
    const u8xR = @Vector(R, u8);
    const u1xR = @Vector(R, u1);
    const uR = @Int(.unsigned, R);

    const uRxN = @Vector(N, uR);
    const NFLUSH_MASKS = N + 1 - 5; // how many suits to check. 3 when N=7 because flush suit must appear in first 3.
    const NSTRT_MASKS = R + 2 - 5;
    const uRxSTRT = @Vector(NSTRT_MASKS, uR);

    const cardsv: u8xN = cards;
    const suits = cardsv & @as(u8xN, @splat(0x3));
    var flushsuit: u8 = 255;
    inline for (0..NFLUSH_MASKS) |i| {
        const same: uN = @bitCast(suits == @as(u8xN, @splat(suits[i])));
        misc.trace(@src(), "same {b}\n", .{same});
        if (@popCount(same) > 4)
            flushsuit = suits[i];
    }

    const ranks = cardsv >> @as(u8xN, @splat(2));
    const ranks_masks = @as(uRxN, @splat(1)) << @truncate(ranks);
    const ranks_mask = @reduce(.Or, ranks_masks); // unique ranks

    var counts: [R]u8 = @splat(0);
    inline for (0..N) |i| {
        counts[ranks[i]] += 1;
    }
    var flushmask: uR = 0;
    if (flushsuit != 255) {
        const flushsuits = suits == @as(u8xN, @splat(flushsuit));
        const flushranks = @select(uR, flushsuits, ranks_masks, @as(uRxN, @splat(0)));
        flushmask = @reduce(.Or, flushranks);
    }

    const countsv: u8xR = counts;
    const singles_mask: uR = @bitCast(@as(u1xR, @bitCast(countsv == @as(u8xR, @splat(1)))));
    const doubles_mask: uR = @bitCast(@as(u1xR, @bitCast(countsv == @as(u8xR, @splat(2)))));
    const triples_mask: uR = @bitCast(@as(u1xR, @bitCast(countsv == @as(u8xR, @splat(3)))));
    const quads_mask: uR = @bitCast(@as(u1xR, @bitCast(countsv == @as(u8xR, @splat(4)))));
    const ALO_STRT_MASK = 0b1111 | (1 << (R - 1)); // A-low
    const S = struct {
        fn highestStraight(ranksmask: uR) ?u8 {
            comptime var straight_masks_all: uRxSTRT = undefined;
            comptime for (0..NSTRT_MASKS - 1) |i| {
                straight_masks_all[i] = 0b11111 << (NSTRT_MASKS - i - 2);
            };
            straight_masks_all[NSTRT_MASKS - 1] = ALO_STRT_MASK;
            // misc.trace(@src(), "{b}\n", .{straight_masks_all});
            const straight_masks = straight_masks_all & @as(uRxSTRT, @splat(ranksmask));
            return if (simd.firstTrue(@popCount(straight_masks) > @as(uRxSTRT, @splat(4)))) |i|
                NSTRT_MASKS - 1 - i
            else
                null;
        }

        fn clearHighestBit(n: uR) uR {
            const bit = @bitSizeOf(uR) - 1 - @clz(n);
            return n & ~(@as(uR, 1) << bit);
        }
    };

    const straightrank = S.highestStraight(ranks_mask);
    var ret: Rank = .uninit;
    const nsingles = @popCount(singles_mask);
    const ndoubles = @popCount(doubles_mask);
    const ntriples = @popCount(triples_mask);
    const strflushrank = S.highestStraight(flushmask);
    const bin_fmt = std.fmt.comptimePrint("{{b:0>{}}}", .{R});
    defer assert(flushsuit == flushsuit);
    defer misc.trace(@src(), // zig fmt: off
        \\cards         :{f}
        \\ranks_mask    :
        ++ bin_fmt ++ \\
        \\counts        :{any}
        \\singles_mask  :
        ++ bin_fmt ++ \\
        \\doubles_mask  :
        ++ bin_fmt ++ \\
        \\triples_mask  :
        ++ bin_fmt ++ \\
        \\quads_mask    :
        ++ bin_fmt ++ \\
        \\              :{},{},{},{}: singles,doubles,triples,quads
        \\flushmask     :
        ++ bin_fmt ++ \\
        \\straightrank  :{?}
        \\strflushrank  :{?}
        \\ret           :{f}
        \\
        \\
    , .{ // zig fmt: on
        Card.Cards.fromIds(&cards).fmtColor(),
        ranks_mask,
        counts,
        singles_mask,
        doubles_mask,
        triples_mask,
        quads_mask,
        nsingles,
        ndoubles,
        ntriples,
        @popCount(quads_mask),
        flushmask,
        straightrank,
        strflushrank,
        ret,
    });

    const class =
        (@as(u3, @intFromBool(flushmask != 0)) << 2) |
        (@as(u3, @intFromBool(straightrank != null)) << 1) |
        @intFromBool(strflushrank != null);

    ret = switch (class) {
        else => .uninit,
        0b111 => .init(.straight_flush, strflushrank.?, 0),
        0b100, 0b110 => .init(.flush, flushmask, 0),
        0b010 => .init(.straight, straightrank.?, 0),
        0b00 => switch (u8Triple(ndoubles, ntriples, @popCount(quads_mask))) {
            u8Triple(0, 0, 1),
            u8Triple(0, 1, 1),
            u8Triple(1, 0, 1),
            => .init(.four_kind, quads_mask, @as(uR, 1) << (R - 1 - @clz(ranks_mask & ~quads_mask))),
            u8Triple(1, 1, 0),
            => .init(.full_house, triples_mask, doubles_mask),
            u8Triple(0, 2, 0),
            => .init(.full_house, triples_mask & (triples_mask - 1), @as(uR, 1) << @ctz(triples_mask)),
            u8Triple(2, 1, 0),
            => .init(.full_house, triples_mask, doubles_mask & (doubles_mask - 1)),
            u8Triple(0, 1, 0),
            => .init(.three_kind, triples_mask, @as(uR, 1) << (R - 1 - @clz(singles_mask))),
            u8Triple(2, 0, 0),
            => .init(.two_pair, doubles_mask, @as(uR, 1) << (R - 1 - @clz(singles_mask))),
            u8Triple(3, 0, 0),
            => .init(
                .two_pair,
                doubles_mask & (doubles_mask - 1),
                @as(uR, 1) << (R - 1 - @clz(singles_mask | S.clearHighestBit(S.clearHighestBit(doubles_mask)))),
            ),
            u8Triple(1, 0, 0),
            => blk: {
                var mask = singles_mask;
                inline for (0..N - 5) |_|
                    mask &= mask - 1;
                break :blk .init(.one_pair, doubles_mask, mask);
            },
            else => blk: {
                var mask = singles_mask;
                inline for (0..N - 5) |_|
                    mask &= mask - 1;
                break :blk .init(.high_card, 0, mask);
            },
        },
    };

    return ret.int();
}

fn u8Pair(a: u8, b: u8) u16 {
    return @bitCast([2]u8{ a, b });
}

fn u8Triple(a: u8, b: u8, c: u8) u32 {
    return @bitCast([4]u8{ 0, a, b, c });
}

const std = @import("std");
const assert = std.debug.assert;
const simd = std.simd;
const mem = std.mem;
const math = std.math;
const Io = std.Io;
pub const Card = @import("card.zig");
pub const rank = @import("rank.zig");
pub const misc = @import("misc.zig");
