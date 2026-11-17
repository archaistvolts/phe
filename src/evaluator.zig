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
        try w.print("{t}:{b:0>13}:{b:0>13}", .{ r.category, r.hi, r.lo });
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
pub fn evaluateNCards(N: comptime_int, R: comptime_int, cards: [N]u8) u32 {
    const u8xR = @Vector(R, u8);
    const u1xR = @Vector(R, u1);
    const uR = @Int(.unsigned, R);
    const NFLUSH_MASKS = N + 1 - 5; // how many suits to check. 3 when N=7 - flush suit must appear in first 3.

    var ranksuits: [R]u8 = @splat(0); // suit bitsets for each rank
    var ranksmask: uR = 0;
    var suitmasks: [4]uR = @splat(0);
    inline for (0..N) |i| {
        const rank = cards[i] >> 2;
        const rankmask = @as(uR, 1) << @truncate(rank);
        ranksmask |= rankmask;
        const suit = cards[i] & 0b11;
        suitmasks[suit] |= rankmask;
        ranksuits[rank] |= @as(u8, 1) << @truncate(suit);
    }

    var flushmask: uR = 0;
    inline for (0..NFLUSH_MASKS) |i| {
        const suit = cards[i] & 0b11;
        const suitsmatch = suitmasks[suit];
        if (@popCount(suitsmatch) > 4) {
            flushmask = suitsmatch;
            break;
        }
    }

    var ret: Rank = .uninit;
    const bin_fmt = std.fmt.comptimePrint("{{b:0>{}}}", .{R});
    defer util.trace(@src(), // zig fmt: off
        \\cards         :{f}
        \\ranksuits     :{b:0>4}
        \\flushmask     :
        ++ bin_fmt ++ \\
        \\ranksmask     :
        ++ bin_fmt ++ \\
        \\ret           :{f}
        \\
        \\
    , .{ // zig fmt: on
        Card.Cards.fromIds(&cards).fmtColor(),
        @as(u8xR, ranksuits),
        flushmask,
        ranksmask,
        ret,
    });

    ret = if (highestStraight(uR, flushmask)) |r|
        .init(.straight_flush, r, 0)
    else if (flushmask != 0) blk: {
        if (N == 5)
            break :blk .init(.flush, flushmask, 0);
        const flushcount = @popCount(flushmask);
        break :blk .init(.flush, (flushmask & (flushmask - @intFromBool(flushcount > 5))), 0);
    } else if (highestStraight(uR, ranksmask)) |r|
        .init(.straight, r, 0)
    else rank: {
        const rankcounts = @popCount(@as(u8xR, ranksuits));
        const single: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(1)))));
        const pair: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(2)))));
        const trip: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(3)))));
        const quad: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(4)))));
        break :rank switch (u8x3_u32(.{ @popCount(pair), @popCount(trip), @popCount(quad) })) {
            u8x3_u32(.{ 0, 0, 1 }),
            => .init(.four_kind, quad, if (N == 5) single else @as(uR, 1) << (R - 1 - @clz(ranksmask & ~quad))),
            u8x3_u32(.{ 0, 1, 1 }),
            u8x3_u32(.{ 1, 0, 1 }),
            => .init(.four_kind, quad, if (N == 5) unreachable else @as(uR, 1) << (R - 1 - @clz(ranksmask & ~quad))),
            u8x3_u32(.{ 1, 1, 0 }),
            => .init(.full_house, trip, pair),
            u8x3_u32(.{ 0, 2, 0 }),
            => .init(.full_house, if (N == 5) unreachable else trip & (trip - 1), @as(uR, 1) << @ctz(trip)),
            u8x3_u32(.{ 2, 1, 0 }),
            => .init(.full_house, trip, if (N == 5) unreachable else pair & (pair - 1)),
            u8x3_u32(.{ 0, 1, 0 }),
            => .init(.three_kind, trip, if (N == 5) single else @as(uR, 1) << (R - 1 - @clz(single))),
            u8x3_u32(.{ 2, 0, 0 }),
            => .init(.two_pair, pair, if (N == 5) single else @as(uR, 1) << (R - 1 - @clz(single))),
            u8x3_u32(.{ 3, 0, 0 }),
            => blk: {
                if (N == 5) unreachable;
                const himask = pair & (pair - 1);
                break :blk .init(.two_pair, himask, @as(uR, 1) << (R - 1 - @clz(ranksmask & ~himask)));
            },
            packInts(3, u8, .{ 1, 0, 0 }),
            => blk: {
                if (N == 5)
                    break :blk .init(.one_pair, pair, single);
                var mask = single;
                inline for (0..N - 5) |_|
                    mask &= mask - 1;
                break :blk .init(.one_pair, pair, mask);
            },
            else => blk: {
                if (N == 5)
                    break :blk .init(.one_pair, 0, single);
                var mask = single;
                inline for (0..N - 5) |_|
                    mask &= mask - 1;
                break :blk .init(.high_card, 0, mask);
            },
        };
    };

    return ret.int();
}

fn highestStraight(T: type, mask: T) ?u8 {
    if (@popCount(mask) < 5)
        return null;

    const starts = mask &
        (mask >> 1) & (mask >> 2) &
        (mask >> 3) & (mask >> 4);

    const width = @bitSizeOf(T);

    const rank = @as(u8, width) + 1 - @clz(starts);
    const WHEEL = 0b1111 | (1 << (width - 1));
    const isnonwheel = starts != 0;
    const ret = rank * @intFromBool(isnonwheel) + @intFromBool(!isnonwheel and (mask & WHEEL) == WHEEL);
    // util.trace(@src(), "mask {b} starts {b} rank {} isnonwheel {} ret {}\n", .{ mask, starts, rank, isnonwheel, ret });
    return ([2]?u8{ ret, null })[@intFromBool(ret == 0)];
}

fn packInts(N: comptime_int, T: type, ints: [N]T) @Int(.unsigned, @bitSizeOf(T) * N) {
    return @bitCast(ints);
}

fn u8x3_u32(ints: anytype) u32 {
    return packInts(3, u8, ints);
}

const std = @import("std");
const assert = std.debug.assert;
const simd = std.simd;
const mem = std.mem;
const math = std.math;
const Io = std.Io;
pub const Card = @import("card.zig");
pub const util = @import("util.zig");
