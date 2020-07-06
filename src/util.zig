const std = @import("std");

pub fn comb5(lo: u6, hi: u6, ch: *std.event.Channel(?[5]u6)) void {
    var a: u6 = lo;
    while (a < hi - 4) : (a += 1) {
        var b: u6 = a + 1;
        while (b < hi - 3) : (b += 1) {
            var c: u6 = b + 1;
            while (c < hi - 2) : (c += 1) {
                var d: u6 = c + 1;
                while (d < hi - 1) : (d += 1) {
                    var e: u6 = d + 1;
                    while (e < hi) : (e += 1) {
                        ch.put([5]u6{ a, b, c, d, e });
                    }
                }
            }
        }
    }
    ch.put(null);
}

pub fn comb7(lo: u6, hi: u6, ch: *std.event.Channel(?[7]u6)) void {
    var y: u6 = lo;
    while (y < hi - 6) : (y += 1) {
        var z: u6 = y + 1;
        while (z < hi - 5) : (z += 1) {
            var a: u6 = z + 1;
            while (a < hi - 4) : (a += 1) {
                var b: u6 = a + 1;
                while (b < hi - 3) : (b += 1) {
                    var c: u6 = b + 1;
                    while (c < hi - 2) : (c += 1) {
                        var d: u6 = c + 1;
                        while (d < hi - 1) : (d += 1) {
                            var e: u6 = d + 1;
                            while (e < hi) : (e += 1) {
                                ch.put([7]u6{ y, z, a, b, c, d, e });
                            }
                        }
                    }
                }
            }
        }
    }
    ch.put(null);
}

test "sanity" {
    var ch: std.event.Channel(?[5]u6) = undefined;
    ch.init(&[_]?[5]u6{});
    _ = async comb5(0, 36, &ch);
    var i: u32 = 0;
    var combs_set = std.AutoHashMap([5]u6, void).init(std.heap.page_allocator);
    while (ch.get()) |comb| : (i += 1) {
        const dupe = try std.heap.page_allocator.create([5]u6);
        for (comb) |e, j| dupe[j] = e;
        _ = try combs_set.put(dupe.*, {});
    }
    std.testing.expectEqual(i, 376992);
    std.testing.expectEqual(combs_set.count(), 376992);

    const combs75 = [_][5]u6{
        .{ 0, 1, 2, 3, 4 },
        .{ 0, 1, 2, 3, 5 },
        .{ 0, 1, 2, 3, 6 },
        .{ 0, 1, 2, 4, 5 },
        .{ 0, 1, 2, 4, 6 },
        .{ 0, 1, 2, 5, 6 },
        .{ 0, 1, 3, 4, 5 },
        .{ 0, 1, 3, 4, 6 },
        .{ 0, 1, 3, 5, 6 },
        .{ 0, 1, 4, 5, 6 },
        .{ 0, 2, 3, 4, 5 },
        .{ 0, 2, 3, 4, 6 },
        .{ 0, 2, 3, 5, 6 },
        .{ 0, 2, 4, 5, 6 },
        .{ 0, 3, 4, 5, 6 },
        .{ 1, 2, 3, 4, 5 },
        .{ 1, 2, 3, 4, 6 },
        .{ 1, 2, 3, 5, 6 },
        .{ 1, 2, 4, 5, 6 },
        .{ 1, 3, 4, 5, 6 },
        .{ 2, 3, 4, 5, 6 },
    };

    ch.init(&[_]?[5]u6{});
    _ = async comb5(0, 7, &ch);
    i = 0;
    while (ch.get()) |comb| : (i += 1) {
        std.testing.expectEqualSlices(u6, &comb, &combs75[i]);
    }
    std.testing.expectEqual(i, combs75.len);
}

// pub fn nested_loop(comptime lo: isize, comptime hi: isize, comptime n: usize, loop_level: usize, data: var, f: var) void {
//     if (loop_level > n) {
//         return f(loop_level, data);
//     }
//     // if we made it past this point,
//     // we need to continue going in the nested loop
//     // for i = [-1, 1]

//     for ([1]void{{}} ** (hi - lo)) |_, i| {
//         // modify entry loop_level
//         // lattice_state[loop_level] = i
//         // modify data here
//         // data[i] += 1;

//         // with entry 1, 2, ..., loop_level fixed,
//         // call function again to go to next level in nested loop
//         nested_loop(lo, hi, n, loop_level + 1, data, f);
//     }
// }

// fn show(ll: usize, data: *[5]u6) void {
//     std.debug.warn("ll: {} ", .{ll});
//     for (data) |e| std.debug.warn("{}, ", .{e});
//     std.debug.warn("\n", .{});
// }

// test "nested_loop" {
//     var data = [1]u6{0} ** 5;
//     nested_loop(0, 7, 5, 0, &data, show);
// }
