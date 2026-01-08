const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "cpu_render",
        .root_module = exe_mod,
    });

    // RGFW deps
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("Xrandr");
    exe.addCSourceFile(.{
        .file = b.path("thirdparty/RGFW/RGFW.c"),
    });

    exe.linkLibC();
    exe.addIncludePath(b.path("thirdparty"));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
