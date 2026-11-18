/// `K` is the number of items to choose from `N`. `K` must be smaller than `N`.
pub fn CombinationIterator(N: comptime_int, K: comptime_int) type {
    return struct {
        current: I,

        const I = @Int(.unsigned, N);
        const start = (1 << K) - 1; //   7c5: 0b0011111
        const limit: I = start << (N - K); // 0b1111100
        const sentinel = std.math.maxInt(I);

        pub const init: @This() = .{ .current = start };

        pub fn next(self: *@This()) ?I {
            comptime assert(sentinel > limit);
            if (self.current == sentinel)
                return null;

            const res = self.current;

            if (res == limit) {
                self.current = sentinel;
                return res;
            }

            // Gosper's Hack
            const c = res & -%res;
            const r = res +% c;
            self.current = (((r ^ res) >> 2) / c) | r;

            return res;
        }

        pub fn randomHand(smith: anytype, buf: *[K]u8) void {
            var used: u64 = 0;
            var out: usize = 0;

            const Smith = @TypeOf(smith);

            // floyd's algorithm: sample K unique ids from [0,N).
            for (N - K..N) |j| {
                const t = (switch (Smith) {
                    *testing.Smith => testing.Smith.valueRangeLessThan,
                    std.Random => std.Random.intRangeLessThan,
                    else => unreachable,
                })(smith, u8, 0, @intCast(j + 1));

                // If t was already selected, take j instead.
                const chosen: u8 = @intCast(if ((used & (@as(u64, 1) << @intCast(t))) != 0) j else t);

                used |= @as(u64, 1) << @intCast(chosen);
                buf[out] = chosen;
                out += 1;
            }

            // randomize order to prevent order-dependent bugs.
            var i: u8 = K;
            while (i > 1) {
                i -= 1;
                const j = (switch (Smith) {
                    *testing.Smith => testing.Smith.valueRangeLessThan,
                    std.Random => std.Random.intRangeLessThan,
                    else => unreachable,
                })(smith, u8, 0, i + 1);
                const tmp = buf[i];
                buf[i] = buf[j];
                buf[j] = tmp;
            }
        }
    };
}

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
