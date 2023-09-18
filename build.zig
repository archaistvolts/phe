const std = @import("std");
const Builder = std.build.Builder;

const build_shared_lib = false;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const tables = b.addSharedLibrary(.{
        .name = "tables",
        .root_source_file = .{ .path = "src/tables.zig" },
        .version = if (build_shared_lib)
            std.builtin.Version.parse("0.0.0") catch unreachable
        else
            null,
        .target = target,
        .optimize = b.standardOptimizeOption(.{
            .preferred_optimize_mode = .ReleaseFast,
        }),
    });
    if (build_shared_lib)
        tables.force_pic = true;
    tables.addCSourceFile(.{
        .file = .{ .path = "src/PokerHandEvaluator/cpp/src/tables_omaha.c" },
        .flags = &[_][]const u8{},
    });
    b.installArtifact(tables);

    const lib =
        b.addSharedLibrary(.{
        .name = "phe",
        .root_source_file = .{ .path = "src/evaluator.zig" },
        .version = if (build_shared_lib)
            std.builtin.Version.parse("0.0.0") catch unreachable
        else
            null,
        .target = target,
        .optimize = optimize,
    });
    if (build_shared_lib) lib.force_pic = true;
    lib.linkLibrary(tables);
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/evaluator_tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.linkLibrary(tables);
    main_tests.linkLibC();
    main_tests.addIncludePath(.{ .path = "src/PokerHandEvaluator/cpp/src/" });
    main_tests.addCSourceFiles(&.{
        "src/PokerHandEvaluator/cpp/src/evaluator_omaha.c",
        "src/PokerHandEvaluator/cpp/src/hash.c",
    }, &.{});
    main_tests.filter = b.option([]const u8, "test-filter", "test filter");
    const options = b.addOptions();
    const gen_option = b.option(bool, "gen", "generate code output to stdout") orelse false;
    options.addOption(bool, "gen", gen_option);
    main_tests.addModule("build_options", options.createModule());
    const test_step = b.step("test", "Run library tests");
    const run_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_tests.step);
    b.installArtifact(main_tests);

    if (false) {
        const exe = b.addExecutable(.{
            .name = "phe",
            .root_source_file = .{ .path = "src/evaluator_tests.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.linkSystemLibrary("tables");
        exe.addLibraryPath("./zig-cache/lib");
        exe.linkLibC();
        exe.addCSourceFiles(&.{
            "src/PokerHandEvaluator/cpp/src/evaluator_omaha.c",
            "src/PokerHandEvaluator/cpp/src/hash.c",
        });
        b.installArtifact(exe);

        //     const tracy = b.option([]const u8, "tracy", "Enable Tracy integration. Supply path to Tracy source");
        //     exe.addBuildOption(bool, "enable_tracy", tracy != null);
        //     if (tracy) |tracy_path| {
        //         const client_cpp = std.fs.path.join(b.allocator, &[_][]const u8{ tracy_path, "TracyClient.cpp" }) catch unreachable;
        //         exe.addIncludeDir(tracy_path);
        //         exe.addCSourceFile(client_cpp, &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" });
        //         exe.linkSystemLibraryName("c++");
        //         exe.linkLibC();
        //     }
    }
}
