const num_hands = 1_000_000;

fn bench(N: comptime_int, comptime R: anytype, random: std.Random, evfn: anytype) void {
    var cards: [N]u8 = undefined;
    for (0..num_hands) |_| {
        @import("combinations.zig").CombinationIterator(52, N).randomHand(random, &cards);
        // std.debug.print("{f}\n", .{ev.Card.Cards.fromIds(&cards).fmtColor()});
        mem.doNotOptimizeAway(evfn(N, R, cards));
    }
}

pub fn main(init: std.process.Init) !void {
    // var args = try init.minimal.args.iterateAllocator(init.gpa);
    // _ = args.next();
    // const raw_cards = try init.gpa.alloc(u8, 1024 * 1024 * 10);

    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();
    const tstart: std.Io.Timestamp = if (options.verbose) .now(init.io, .cpu_process) else undefined;

    switch (options.bench_target) {
        .phe_c => bench(options.benchN, options.benchR, random, phe_c.evaluateNCards),
        .phe_z => bench(options.benchN, options.benchR, random, phe_z.evaluateCards),
        .ev_z => bench(options.benchN, @as(ev.Deck, @fromBackingInt(options.benchR)), random, ev.evaluateNCards),
    }

    if (options.verbose) {
        const telapsed = tstart.untilNow(init.io, .cpu_process);
        std.debug.print(
            "{} hands in {f}: {:.1}M/s\n",
            .{ num_hands, telapsed, @as(f64, num_hands) / @as(f64, @floatFromInt(telapsed.toMicroseconds())) },
        );
    }
}

const std = @import("std");
const mem = std.mem;
const ev = @import("evaluator.zig");
const phe_c = @import("phe_c.zig");
const phe_z = @import("phe");
const options = @import("build-options");
