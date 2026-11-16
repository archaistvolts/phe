const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = b.addOptions();
    const options_mod = options.createModule();
    options.addOption(bool, "trace", b.option(bool, "trace", "show debug trace output. default false.") orelse false);
    const phe_option = b.option(bool, "phe", "run phe in bench. only applies to `zig build bench`") orelse false;
    options.addOption(bool, "phe", phe_option);
    options.addOption(u8, "benchN", b.option(u8, "benchN", "number of cards per hand. default 7.") orelse 7);
    options.addOption(u8, "benchR", b.option(u8, "benchR", "number of ranks per suit. default 13.") orelse 13);
    const strip = b.option(bool, "strip", "strip debug symbols");

    const root_mod = b.addModule("evaluator", .{
        .root_source_file = b.path("src/evaluator.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "build-options", .module = options_mod }},
        .strip = strip,
    });

    const phe_dep = b.dependency("PokerHandEvaluator", .{ .target = target, .optimize = optimize });
    const phe_mod = b.createModule(.{ .target = target, .optimize = optimize });
    phe_mod.link_libc = true;
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/evaluator5.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/evaluator7.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/evaluator_omaha.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/hash.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/tables_omaha.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/hashtable.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/hashtable5.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/hashtable7.c") });
    phe_mod.addCSourceFile(.{ .file = phe_dep.path("cpp/src/dptables.c") });
    phe_mod.addIncludePath(phe_dep.path("cpp/src"));

    var tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/evaluator_tests.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "evaluator", .module = root_mod },
                .{ .name = "phe", .module = phe_mod },
            },
        }),
    });
    tests.filters = if (b.option([]const u8, "test-filter", "test filter")) |f| b.dupeStrings(&.{f}) else &.{};
    const teststep = b.step("test", "Run library tests");
    const testsrun = b.addRunArtifact(tests);
    testsrun.has_side_effects = true;
    teststep.dependOn(&testsrun.step);
    b.installArtifact(tests);

    const bench = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "evaluator", .module = root_mod },
                .{ .name = "phe", .module = if (phe_option) phe_mod else undefined },
                .{ .name = "build-options", .module = options_mod },
            },
            .strip = strip,
        }),
    });
    const benchstep = b.step("bench", "Run a benchmark");
    const benchrun = b.addRunArtifact(bench);
    benchrun.has_side_effects = true;
    benchstep.dependOn(&benchrun.step);
    b.installArtifact(bench);

    const exe_check = b.addExecutable(.{ .name = "check", .root_module = root_mod });
    const check = b.step("check", "Check if everything compiles");
    check.dependOn(&exe_check.step);
    check.dependOn(&tests.step);
    check.dependOn(&bench.step);

    // const wasm_lib = b.addExecutable(.{
    //     .name = "poker-evaluator",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/export.zig"),
    //         .target = b.resolveTargetQuery(try .parse(.{ .arch_os_abi = "wasm32-freestanding" })),
    //         .optimize = optimize,
    //     }),
    // });
    // wasm_lib.import_symbols = true;
    // wasm_lib.entry = .disabled;
    // wasm_lib.rdynamic = true;
    // b.installArtifact(wasm_lib);
}
