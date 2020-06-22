const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const tables = b.addStaticLibrary("tables", "src/tables.zig");
    tables.addCSourceFile("src/PokerHandEvaluator/cpp/src/tables_omaha.c", &[_][]const u8{});
    tables.setBuildMode(std.builtin.Mode.ReleaseFast);
    tables.install();

    const lib = b.addStaticLibrary("phe", "src/evaluator.zig");
    // const mode = b.standardReleaseOptions();
    // lib.setBuildMode(mode);
    const mode = std.builtin.Mode.ReleaseSafe;
    lib.setBuildMode(mode);
    lib.linkSystemLibrary("tables");
    lib.addLibPath("./zig-cache/lib");
    lib.install();

    var main_tests = b.addTest("src/evaluator.zig");
    main_tests.setBuildMode(mode);
    main_tests.linkSystemLibrary("tables");
    main_tests.addLibPath("./zig-cache/lib");
    main_tests.linkLibC();
    main_tests.addIncludeDir("src/PokerHandEvaluator/cpp/src/");
    main_tests.addCSourceFile("src/PokerHandEvaluator/cpp/src/evaluator_omaha.c", &[_][]const u8{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
