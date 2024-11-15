const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tetris",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    switch (target.result.os.tag) {
        .windows => {
            exe.root_module.addImport("io", b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/io_windows.zig" } },
            }));
        },
        else => {
            exe.root_module.addImport("io", b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/io_unix.zig" } },
            }));
            exe.linkSystemLibrary("curses");
        },
    }
    b.installArtifact(exe);
}
