const std = @import("std");

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Test exception matching across a shared libc++ boundary");
    b.default_step = test_step;
    const host = b.graph.host.result;
    if (host.os.tag != .linux or !host.abi.isGnu()) return;
    const target = b.fmt("{s}-linux-gnu", .{@tagName(host.cpu.arch)});

    const runtime = zigCommand(b, &.{
        "build-lib", "-dynamic", "-lc++",   "-fbuild-shared-libcpp",
        "--name",    "c++",      "-target", target,
    });
    runtime.addArg("--zig-lib-dir");
    runtime.addDirectoryArg(.zig_lib);
    const runtime_so = runtime.addPrefixedOutputFileArg("-femit-bin=", "libc++.so");

    const library = zigCommand(b, &.{
        "c++",               "-target",             target,       "-shared",                   "-fPIC",
        "-shared-libstdc++", "-fvisibility=hidden", "-std=c++17", "-Wl,-soname,libthrower.so",
    });
    library.addFileArg(b.path("thrower.cpp"));
    library.addPrefixedDirectoryArg("-L", runtime_so.dirname());
    library.addDirectoryArg2(runtime_so.dirname(), .{ .prefix = "-Wl,-rpath,", .make_absolute = true });
    library.addArg("-o");
    const library_so = library.addOutputFileArg("libthrower.so");

    const executable = zigCommand(b, &.{
        "c++", "-target", target, "-fshared-libcpp", "-std=c++17",
    });
    executable.addFileArg(b.path("main.cpp"));
    executable.addFileArg(library_so);
    executable.addPrefixedDirectoryArg("-L", runtime_so.dirname());
    executable.addDirectoryArg2(runtime_so.dirname(), .{ .prefix = "-Wl,-rpath,", .make_absolute = true });
    executable.addDirectoryArg2(library_so.dirname(), .{ .prefix = "-Wl,-rpath,", .make_absolute = true });
    executable.addArg("-o");
    const executable_bin = executable.addOutputFileArg("catch_exception");

    const run = std.Build.Step.Run.create(b, "run shared libc++ exception test");
    run.addFileArg(executable_bin);
    run.expectExitCode(0);
    run.expectStdOutEqual(
        \\throwing case 0
        \\caught std::exception: std::exception
        \\throwing case 1
        \\caught std::exception: exception from shared library
        \\throwing case 2
        \\caught std::exception: runtime_error from shared library
        \\throwing case 3
        \\caught ...
        \\
    );
    test_step.dependOn(&run.step);
}

fn zigCommand(b: *std.Build, args: []const []const u8) *std.Build.Step.Run {
    const run = std.Build.Step.Run.create(b, "zig shared libc++ test command");
    // Hash the compiler file too, so a compiler edit cannot reuse old test output.
    run.addFileArg(.zig_exe);
    run.addArgs(args);
    return run;
}
