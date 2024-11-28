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
            const io_path = "src/io_windows.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            exe.root_module.addImport("io", io);
        },
        .macos => {
            const io_path = "src/io_posix.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            const spoon = b.dependency("zig-spoon", .{ .optimize = optimize, .target = target });
            io.addImport("spoon", spoon.module("spoon"));
            exe.root_module.addImport("io", io);
        },
        else => {
            const io_path = "src/io_posix.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            const spoon = b.dependency("zig-spoon", .{ .optimize = optimize, .target = target });
            io.addImport("spoon", spoon.module("spoon"));
            exe.root_module.addImport("io", io);
        },
    }
    b.installArtifact(exe);
}
