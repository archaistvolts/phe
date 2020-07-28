const std = @import("std");
const Builder = std.build.Builder;

const build_shared_lib = false;

pub fn build(b: *Builder) void {
    const tables = if (build_shared_lib)
        b.addSharedLibrary("tables", "src/tables.zig", std.builtin.Version.parse("0.0.0") catch unreachable)
    else
        b.addStaticLibrary("tables", "src/tables.zig");
    if (build_shared_lib)
        tables.force_pic = true;
    tables.addCSourceFile("src/PokerHandEvaluator/cpp/src/tables_omaha.c", &[_][]const u8{});
    tables.setBuildMode(std.builtin.Mode.ReleaseFast);
    tables.install();

    const lib = if (build_shared_lib)
        b.addSharedLibrary("phe", "src/evaluator.zig", std.builtin.Version.parse("0.0.0") catch unreachable)
    else
        b.addStaticLibrary("phe", "src/evaluator.zig");
    if (build_shared_lib)
        lib.force_pic = true;
    const mode = b.standardReleaseOptions();
    lib.setBuildMode(mode);
    lib.linkSystemLibrary("tables");
    lib.addLibPath("./zig-cache/lib");
    lib.install();

    var main_tests = b.addTest("src/evaluator_tests.zig");
    main_tests.setBuildMode(mode);
    main_tests.linkSystemLibrary("tables");
    main_tests.addLibPath("./zig-cache/lib");
    main_tests.linkLibC();
    main_tests.addIncludeDir("src/PokerHandEvaluator/cpp/src/");
    main_tests.addCSourceFile("src/PokerHandEvaluator/cpp/src/evaluator_omaha.c", &[_][]const u8{});
    main_tests.setFilter("fuzz");
    main_tests.test_evented_io = true;
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // const exe = b.addExecutable("phe", "src/evaluator_tests.zig");
    // exe.setBuildMode(mode);
    // exe.linkSystemLibrary("tables");
    // exe.addLibPath("./zig-cache/lib");
    // exe.install();

    // if (false) {
    //     const tracy = b.option([]const u8, "tracy", "Enable Tracy integration. Supply path to Tracy source");
    //     exe.addBuildOption(bool, "enable_tracy", tracy != null);
    //     if (tracy) |tracy_path| {
    //         const client_cpp = std.fs.path.join(b.allocator, &[_][]const u8{ tracy_path, "TracyClient.cpp" }) catch unreachable;
    //         exe.addIncludeDir(tracy_path);
    //         exe.addCSourceFile(client_cpp, &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" });
    //         exe.linkSystemLibraryName("c++");
    //         exe.linkLibC();
    //     }
    // }
}
