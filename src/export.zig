const std = @import("std");
const Card = @import("card.zig");
const Rank = @import("rank.zig");
const ev = @import("evaluator.zig");

pub export fn evaluate_5hand_w(hand: [*]const u8) c_short {
    const rank = ev.evaluate5Hand(hand[0..10], 13);
    return @as(c_short, @intCast(rank.value));
}

// pub export fn hash_quinary5_w(q: *c_void, num_ranks: u8, k: u8) c_ulong {
//     const p = @ptrCast([*]u8, q);
//     var ids: [52]u6 = undefined;
//     for (ids[0..num_ranks]) |*id, i| id.* = @intCast(u6, p[i]);
//     return @intCast(c_ulong, ev.hashQuinary(ids[0..num_ranks], num_ranks, k));
// }

pub export fn evaluate_5cards_w(a: u8, b: u8, c: u8, d: u8, e: u8) c_ushort {
    return ev.evaluate5Cards(
        Card.init(a),
        Card.init(b),
        Card.init(c),
        Card.init(d),
        Card.init(e),
        13,
    ).value;
}

pub export fn evaluate_7cards_w(a: u8, b: u8, c: u8, d: u8, e: u8, f: u8, g: u8) c_ushort {
    return ev.evaluate7Cards(
        Card.init(a),
        Card.init(b),
        Card.init(c),
        Card.init(d),
        Card.init(e),
        Card.init(f),
        Card.init(g),
        13,
    ).value;
}

pub export fn evaluate_7hand_w(hand: [*]const u8) c_short {
    const rank = ev.evaluate7Hand(hand[0..14], 13);
    return @intCast(rank.value);
}

pub export fn cards_to_binary5_w(hand: [*]const u8) u16 {
    debug("cards_to_binary5_w hand {s}\n", .{@as([]const u8, hand[0..10])});
    return ev.cardsToBinary(&Card.cardsFromString(5, hand[0..10]));
}

pub export fn cards_to_binary7_w(hand: [*]const u8) u16 {
    // print("cards_to_binary7_w hand {}\n", .{hand[0..14]});
    return ev.cardsToBinary(&Card.cardsFromString(7, hand[0..14]));
}

extern "js" fn consoleLog([*]const u8, i32) void;
extern "js" var mem: [*]u8;

fn debug(comptime fmt: []const u8, args: anytype) void {
    // var cw = std.io.countingWriter(std.io.null_writer);
    // cw.writer().print(fmt, args) catch @panic("unreachable");
    // const buf = allocator.alloc(u8, @intCast(cw.bytes_written)) catch @panic("OOM");
    var buf: [1024]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, fmt, args) catch @panic("OOM");
    consoleLog(s.ptr, @intCast(s.len));
}

var arena = std.heap.ArenaAllocator.init(std.heap.wasm_allocator);
const allocator = arena.allocator();

export fn alloc(length: u32) [*]const u8 {
    const slice = allocator.alloc(u8, length) catch
        @panic("failed to allocate memory");
    return slice.ptr;
}

export fn free(ptr: [*]const u8, len: u32) void {
    allocator.free(ptr[0..len]);
}

pub export fn cards_from_string(len: u8, hand: [*]const u8) [*]const u8 {
    // debug("cards_from_string({}, {s})\n", .{ len, hand[0 .. len * 2] });
    switch (len) {
        inline 5, 7 => |n| {
            const cards = Card.cardsFromString(n, hand[0 .. n * 2]);
            for (0..n) |i| mem[i] = cards[i].id;
            return mem;
        },
        else => std.debug.panic(
            "unexpected length {} cards_from_string({}, '{s}')",
            .{ len, len, hand[0..len] },
        ),
    }
    unreachable;
}
