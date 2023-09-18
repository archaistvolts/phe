value: u16,

const std = @import("std");
const Rank = @This();

pub fn init(value: u16) Rank {
    return .{ .value = value };
}

pub fn category(rank: Rank) Category {
    inline for (Category.rank_infos) |ri| {
        if (rank.value <= ri[2]) return ri[0];
    }
    return .invalid;
}

pub fn categoryToSd(rank: Rank) Category {
    return switch (rank.value) {
        167...1443 => .flush,
        1444...1599 => .full_house,
        else => category(rank),
    };
}

pub fn sdAdjusted(rank: Rank) Rank {
    return init(switch (rank.category()) {
        .flush => rank.value - 156,
        .full_house => rank.value + 1277,
        else => rank.value,
    });
}

pub const Category = enum {
    straight_flush,
    four_of_a_kind,
    full_house,
    flush,
    straight,
    three_of_a_kind,
    two_pair,
    one_pair,
    high_card,
    invalid,

    pub fn describe(cat: Category) []const u8 {
        return descriptions[cat.id()];
    }

    pub fn id(cat: Category) std.meta.Tag(Category) {
        return @intFromEnum(cat);
    }

    const descriptions = [_][]const u8{
        "Straight Flush",
        "Four of a Kind",
        "Full House",
        "Flush",
        "Straight",
        "Three of a Kind",
        "Two Pair",
        "One Pair",
        "High Card",
        "Invalid",
    };

    // 13 card distinct: 10, 156, 156, 1277, 10,   858,  858,  2860, 1277
    //  13 card offsets: 10, 166, 322, 1599, 1609, 2467, 3325, 6185, 7462
    //  13 card offsets short deck:
    //                 : 10, 166, 1443,1599, 1609, 2467, 3325, 6185, 7462
    pub const rank_infos = .{
        // 13c: distinct, end, begin, begin sd adjusted,
        .{ .straight_flush, 10, 10, 0, 0 },
        .{ .four_of_a_kind, 156, 166, 10, 10 },
        .{ .full_house, 156, 322, 166, 1443 },
        .{ .flush, 1277, 1599, 322, 166 },
        .{ .straight, 10, 1609, 1599, 1599 },
        .{ .three_of_a_kind, 858, 2467, 1609, 1609 },
        .{ .two_pair, 858, 3325, 2467, 2467 },
        .{ .one_pair, 2860, 6185, 3325, 3325 },
        .{ .high_card, 1277, 7462, 6185, 6185 },
        .{ .invalid, 1, 7463, 7462, 7462 },
    };

    pub fn size(cat: Category) u16 {
        inline for (rank_infos) |ri| {
            if (cat == ri[0]) return ri[1];
        }
        @panic("invalid category");
    }

    pub fn begin(cat: Category) u16 {
        inline for (rank_infos) |ri| {
            if (cat == ri[0]) return ri[3];
        }
        @panic("invalid category");
    }

    pub fn end(cat: Category) u16 {
        inline for (rank_infos) |ri| {
            if (cat == ri[0]) return ri[2];
        }
        @panic("invalid category");
    }

    pub fn beginSdAdjusted(cat: Category) u16 {
        inline for (rank_infos) |ri| {
            if (cat == ri[0]) return ri[4];
        }
        @panic("invalid category");
    }

    pub fn endSdAdjusted(cat: Category) u16 {
        return cat.beginSdAdjusted() + cat.size();
    }
};
