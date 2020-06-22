value: u16,

const Self = @This();

pub const rank_category = enum {
    FiveOfAKind, // Reserved
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
    "Invalid",
};

pub fn category(rank: Self) rank_category {
    if (rank.value > 6185) return .high_card; // 1277 high card
    if (rank.value > 3325) return .one_pair; // 2860 one pair
    if (rank.value > 2467) return .two_pair; //  858 two pair
    if (rank.value > 1609) return .three_of_a_kind; //  858 three-kind
    if (rank.value > 1599) return .straight; //   10 straights
    if (rank.value > 322) return .flush; // 1277 flushes
    if (rank.value > 166) return .full_house; //  156 full house
    if (rank.value > 10) return .four_of_a_kind; //  156 four-kind
    return .straight_flush; //   10 straight-flushes
}

// pub fn describe_rank(rank: u16) []const u8 {
//     return rank_description[rank][1];
// }

// pub fn describe_sample_hand(rank: u16) []const u8 {
//     return rank_description[rank][0];
// }

pub fn is_flush(rank: u16) bool {
    return switch (get_rank_category(rank)) {
        .straight_flush, .flush => true,
        else => false,
    };
}
