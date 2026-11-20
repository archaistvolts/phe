//! # Resources
//!
//! https://github.com/zekyll/OMPEval
//! https://github.com/HenryRLee/PokerHandEvaluator
//! https://github.com/tangentforks/TwoPlusTwoHandEvaluator
//! https://github.com/kennethshackleton/SKPokerEval
//! https://jonathanhsiao.com/blog/evaluating-poker-hands-with-bit-math
//! https://github.com/eljefeo/dead-horse-eval/
//! https://github.com/kennethshackleton/SKPokerEval
//!

pub const Category = enum(u6) {
    high_card,
    one_pair,
    two_pair,
    three_kind,
    straight,
    flush,
    full_house,
    four_kind,
    straight_flush,

    high_card_shortdeck,
    one_pair_shortdeck,
    two_pair_shortdeck,
    three_kind_shortdeck,
    straight_shortdeck,
    full_house_shortdeck,
    flush_shortdeck,
    four_kind_shortdeck,
    straight_flush_shortdeck,

    pub fn beginRank(cat: Category) Rank {
        return .{ .category = cat, .hi = 0, .lo = 0 };
    }

    pub fn endRank(cat: Category) Rank {
        return .{ .category = cat, .hi = math.maxInt(u13), .lo = math.maxInt(u13) };
    }

    pub fn describe(cat: Category) []const u8 {
        return descriptions[@backingInt(cat)];
    }

    const descriptions = [_][]const u8{
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

pub const Rank = packed struct(u32) {
    lo: u13,
    hi: u13,
    category: Category,

    pub const uninit: Rank = @fromBackingInt(0);

    pub fn init(category: Category, hi: u13, lo: u13) Rank {
        return .{ .category = category, .hi = hi, .lo = lo };
    }

    pub fn fromInt(r: u32) Rank {
        return @fromBackingInt(r);
    }

    pub fn int(r: Rank) u32 {
        return @backingInt(r);
    }

    pub fn toShort(r: Rank) Rank {
        assert(@backingInt(r.category) < @backingInt(Category.high_card_shortdeck)); // don't allow short to short
        return .{
            .hi = r.hi,
            .lo = r.lo,
            .category = switch (r.category) {
                inline .high_card_shortdeck,
                .one_pair_shortdeck,
                .two_pair_shortdeck,
                .three_kind_shortdeck,
                .straight_shortdeck,
                .flush_shortdeck,
                .full_house_shortdeck,
                .four_kind_shortdeck,
                .straight_flush_shortdeck,
                => unreachable,
                inline else => |t| @field(Category, @tagName(t) ++ "_shortdeck"),
            },
        };
    }

    pub fn format(r: Rank, w: *Io.Writer) !void {
        try w.print("{t}:{b:0>6}:{b:0>13}:{b:0>13}", .{ r.category, @backingInt(r.category), r.hi, r.lo });
    }
};

pub const Deck = enum(u8) {
    /// 52 cards
    full = 13,
    /// 36 cards
    short = 9,
    pub fn int(d: Deck) u8 {
        return @backingInt(d);
    }
};

pub fn evaluateNHand(N: comptime_int, comptime R: Deck, hand: []const u8) Rank {
    assert(hand.len == N * 2);
    var ids: [N]u8 = undefined;
    Cards.idsFromNames(R, hand, &ids);
    return evaluateNCards(N, R, ids);
}

pub fn evaluateNCards(N: comptime_int, comptime R: Deck, cards: [N]u8) Rank {
    const NRANKS: u4 = @backingInt(R);
    const u8xR = @Vector(NRANKS, u8);
    const u1xR = @Vector(NRANKS, u1);
    const uR = @Int(.unsigned, NRANKS);

    var ranksuits: [NRANKS]u8 = @splat(0); // suit masks by rank
    var ranks: uR = 0; // all ranks mask
    var suits: [4]uR = @splat(0); // rank masks by suit
    inline for (0..N) |i| {
        const rank = cards[i] >> 2;
        assert(rank < NRANKS);
        const suit = cards[i] & 0b11;
        const rankmask = @as(uR, 1) << @truncate(rank);
        ranks |= rankmask;
        const suitmask = @as(u8, 1) << @truncate(suit);
        suits[suit] |= rankmask;
        ranksuits[rank] |= suitmask;
    }

    var flush: uR = 0;
    inline for (0..N - 4) |i| { // 0..3 when N=7
        comptime assert(N < 10); // assumes only 1 flush possible in N cards
        const candidateflush = suits[cards[i] & 0b11];
        if (@popCount(candidateflush) > 4) {
            flush = candidateflush;
            break;
        }
    }

    var ret: Rank = (if (highestStraight(uR, flush)) |r|
        .init(.straight_flush, r, 0)
    else if (flush != 0)
        if (N == 5)
            .init(.flush, flush, 0)
        else blk: {
            const count = @popCount(flush);
            flush &= flush - @intFromBool(count >= 6);
            flush &= flush - @intFromBool(count >= 7);
            break :blk .init(.flush, flush, 0);
        }
    else if (highestStraight(uR, ranks)) |r|
        .init(.straight, r, 0)
    else rank: {
        // benchmarks show simd speedup here vs scalar inline loop
        const rankcounts = @popCount(@as(u8xR, ranksuits));
        var single: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(1)))));
        var pair: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(2)))));
        var trip: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(3)))));
        const quad: uR = @bitCast(@as(u1xR, @bitCast(rankcounts == @as(u8xR, @splat(4)))));

        inline for (0..N - 5) |_|
            single &= single -| 1;
        break :rank switch (u8x3_u32(.{ @popCount(pair), @popCount(trip), @popCount(quad) })) {
            u8x3_u32(.{ 0, 0, 1 }) => .init(.four_kind, quad, single),
            u8x3_u32(.{ 0, 1, 1 }),
            u8x3_u32(.{ 1, 0, 1 }),
            => if (N == 5)
                unreachable
            else
                .init(.four_kind, quad, @as(uR, 1) << (NRANKS - 1 - @clz(ranks & ~quad))),
            u8x3_u32(.{ 1, 1, 0 }) => .init(.full_house, trip, pair),
            u8x3_u32(.{ 0, 2, 0 }),
            => if (N == 5)
                unreachable
            else blk: {
                trip &= trip - 1;
                break :blk .init(.full_house, trip, ~trip);
            },
            u8x3_u32(.{ 2, 1, 0 }),
            => if (N == 5)
                unreachable
            else
                .init(.full_house, trip, pair & (pair - 1)),
            u8x3_u32(.{ 0, 1, 0 }) => .init(.three_kind, trip, single),
            u8x3_u32(.{ 2, 0, 0 }) => .init(.two_pair, pair, single),
            u8x3_u32(.{ 3, 0, 0 }),
            => if (N == 5)
                unreachable
            else blk: {
                pair &= pair - 1;
                break :blk .init(.two_pair, pair, @as(uR, 1) << (NRANKS - 1 - @clz(ranks & ~pair)));
            },
            packInts(3, u8, .{ 1, 0, 0 }) => .init(.one_pair, pair, single),
            else => .init(.high_card, 0, single),
        };
    });

    const bin_fmt = std.fmt.comptimePrint("{{b:0>{}}}", .{NRANKS});
    defer util.trace(@src(), // zig fmt: off
        \\cards         :{f}
        \\ranksuits     :{b:0>4}
        \\flushmask     :
        ++ bin_fmt ++ \\
        \\ranks         :
        ++ bin_fmt ++ \\
        \\ret           :{f}
        \\
        \\
    , .{ // zig fmt: on
        Cards.fromIds(R, &cards).fmtColor(),
        @as(u8xR, ranksuits),
        flush,
        ranks,
        ret,
    });

    if (NRANKS == 9)
        ret = ret.toShort();

    return ret;
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
pub const Card = @import("Card.zig");
pub const Cards = @import("Cards.zig");
pub const util = @import("util.zig");
