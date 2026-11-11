const std = @import("std");
const build_shared_lib = false;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("src/tables.zig"),
        .target = target,
        .optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall }),
    });
    tables_mod.addCSourceFile(.{ .file = b.path("src/PokerHandEvaluator/cpp/src/tables_omaha.c") });
    tables_mod.export_symbol_names = &.{"flush"};

    const tables = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "tables",
        .root_module = tables_mod,
        .version = if (build_shared_lib)
            std.SemanticVersion.parse("0.0.0") catch unreachable
        else
            null,
    });
    if (build_shared_lib) tables.force_pic = true;
    b.installArtifact(tables);

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/evaluator.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .name = "phe",
        .root_module = root_mod,
        .version = if (build_shared_lib)
            std.SemanticVersion.parse("0.0.0") catch unreachable
        else
            null,
    });
    if (build_shared_lib) lib.force_pic = true;
    root_mod.linkLibrary(tables);
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/evaluator_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    main_tests.root_module.linkLibrary(tables);
    main_tests.root_module.link_libc = true;
    main_tests.root_module.addCSourceFiles(.{ .files = &.{
        "src/PokerHandEvaluator/cpp/src/evaluator5.c",
        "src/PokerHandEvaluator/cpp/src/evaluator7.c",
        "src/PokerHandEvaluator/cpp/src/evaluator_omaha.c",
        "src/PokerHandEvaluator/cpp/src/hash.c",
    }, .flags = &.{} });
    main_tests.filters = if (b.option([]const u8, "test-filter", "test filter")) |f| b.dupeStrings(&.{f}) else &.{};
    const options = b.addOptions();
    const gen_option = b.option(bool, "gen", "generate code output to stdout") orelse false;
    options.addOption(bool, "gen", gen_option);
    main_tests.root_module.addImport("build_options", options.createModule());
    const test_step = b.step("test", "Run library tests");
    const run_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_tests.step);
    b.installArtifact(main_tests);

    const wasm_lib = b.addLibrary(.{
        .name = "phe",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/export.zig"),
            .target = b.resolveTargetQuery(try .parse(.{ .arch_os_abi = "wasm32-freestanding" })),
            .optimize = optimize,
        }),
    });
    wasm_lib.import_symbols = true;
    b.installArtifact(wasm_lib);
}
