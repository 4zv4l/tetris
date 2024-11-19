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
        .macos => {
            exe.root_module.addImport("io", b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/io_macos.zig" } },
            }));
            exe.linkSystemLibrary("curses");
        },
        else => {
            const spoon = b.dependency("zig-spoon", .{ .optimize = optimize, .target = target });
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/io_unix.zig" } },
            });
            io.addImport("spoon", spoon.module("spoon"));
            exe.root_module.addImport("io", io);
        },
    }
    b.installArtifact(exe);
}
