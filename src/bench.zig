fn bench(N: comptime_int, R: comptime_int, deck: *[52]u8, random: std.Random, evfn: anytype) void {
    var r = std.Io.Reader.fixed(deck);
    for (0..1_000_000) |_| {
        const hand = r.take(N) catch blk: {
            random.shuffle(u8, deck);
            r = .fixed(deck);
            break :blk r.take(N) catch unreachable;
        };
        // std.debug.print("{f}\n", .{ev.Card.Cards.fromIds(hand)});
        mem.doNotOptimizeAway(evfn(N, R, hand[0..N].*));
    }
}

pub fn main(init: std.process.Init) !void {
    _ = init; // autofix
    // var args = try init.minimal.args.iterateAllocator(init.gpa);
    // _ = args.next();
    // const raw_cards = try init.gpa.alloc(u8, 1024 * 1024 * 10);

    var deck: [52]u8 = std.simd.iota(u8, 52);
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    random.shuffle(u8, &deck);
    if (options.phe) {
        bench(options.benchN, options.benchR, &deck, random, phe_c.evaluateNCards);
    } else {
        bench(options.benchN, options.benchR, &deck, random, ev.evaluateNCards);
    }
}

const std = @import("std");
const mem = std.mem;
const ev = @import("evaluator.zig");
const phe_c = @import("phe_c.zig");
const options = @import("build-options");
