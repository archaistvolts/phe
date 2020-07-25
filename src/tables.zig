pub extern const noflush_omaha: [11238500]u16;
pub extern const flush_omaha: [4099095]u16;

const ht = @import("hashtable.zig");
const ht5 = @import("hashtable5.zig");
const ht7 = @import("hashtable7.zig");
const sd5 = @import("hashtable_sd5.zig");
const sd7 = @import("hashtable_sd7.zig");
const dpt = @import("dptables.zig");
const razz5 = @import("razz_hashtable5.zig");
// const razz = @import("razz_hashtable.zig");

export const flush = ht.flush;
export const noflush5 = ht5.noflush5;
export const noflush7 = ht7.noflush7;
export const choose = dpt.choose;
export const dp = dpt.dp;
export const suits = dpt.suits;
export const flush_sd5 = sd5.flushes;
export const noflush_sd5 = sd5.nonflushes;
export const flush_sd7 = sd7.flushes;
export const noflush_sd7 = sd7.nonflushes;
export const razz_hashtable5 = razz5.razz_lookup5;
