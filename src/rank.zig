value: u16,

const Self = @This();

const rank_category = enum {
    FIVE_OF_A_KIND, // Reserved
    STRAIGHT_FLUSH,
    FOUR_OF_A_KIND,
    FULL_HOUSE,
    FLUSH,
    STRAIGHT,
    THREE_OF_A_KIND,
    TWO_PAIR,
    ONE_PAIR,
    HIGH_CARD,

    pub fn describe(rc: rank_category) []const u8 {
        return rank_category_description[@enumToInt(rc)];
    }
};

const rank_category_description = [_][]const u8{
    "",
    "Straight Flush",
    "Four of a Kind",
    "Full House",
    "Flush",
    "Straight",
    "Three of a Kind",
    "Two Pair",
    "One Pair",
    "High Card",
};

pub fn category(rank: Self) rank_category {
    if (rank.value > 6185) return .HIGH_CARD; // 1277 high card
    if (rank.value > 3325) return .ONE_PAIR; // 2860 one pair
    if (rank.value > 2467) return .TWO_PAIR; //  858 two pair
    if (rank.value > 1609) return .THREE_OF_A_KIND; //  858 three-kind
    if (rank.value > 1599) return .STRAIGHT; //   10 straights
    if (rank.value > 322) return .FLUSH; // 1277 flushes
    if (rank.value > 166) return .FULL_HOUSE; //  156 full house
    if (rank.value > 10) return .FOUR_OF_A_KIND; //  156 four-kind
    return .STRAIGHT_FLUSH; //   10 straight-flushes
}

// pub fn describe_rank(rank: u16) []const u8 {
//     return rank_description[rank][1];
// }

// pub fn describe_sample_hand(rank: u16) []const u8 {
//     return rank_description[rank][0];
// }

pub fn is_flush(rank: u16) bool {
    return switch (get_rank_category(rank)) {
        .STRAIGHT_FLUSH, .FLUSH => true,
        else => false,
    };
}
