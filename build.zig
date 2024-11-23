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

    const gui = b.option(bool, "gui", "use gui instead of tui (raylib)") orelse false;
    switch (target.result.os.tag) {
        .windows => {
            const io_path = if (gui) "src/io_raylib.zig" else "src/io_windows.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            if (gui) {
                io.addIncludePath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_win64_mingw-w64/include/",
                } });
                exe.addLibraryPath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_win64_mingw-w64/lib/",
                } });
            }
            exe.linkSystemLibrary("raylib");
            exe.root_module.addImport("io", io);
        },
        .macos => {
            const io_path = if (gui) "src/io_raylib.zig" else "src/io_macos.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            if (gui) {
                io.addIncludePath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_macos/include/",
                } });
                exe.addLibraryPath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_macos/lib/",
                } });
                exe.linkSystemLibrary("raylib");
            } else {
                exe.linkSystemLibrary("curses");
            }
            exe.root_module.addImport("io", io);
        },
        else => {
            const io_path = if (gui) "src/io_raylib.zig" else "src/io_unix.zig";
            const io = b.createModule(.{
                .optimize = optimize,
                .target = target,
                .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = io_path } },
            });
            if (gui) {
                io.addIncludePath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_linux_amd64/include/",
                } });
                exe.addLibraryPath(.{ .src_path = .{
                    .owner = b,
                    .sub_path = "./lib/raylib-5.5_linux_amd64/lib",
                } });
                exe.linkSystemLibrary("raylib");
            } else {
                const spoon = b.dependency("zig-spoon", .{ .optimize = optimize, .target = target });
                io.addImport("spoon", spoon.module("spoon"));
            }
            exe.root_module.addImport("io", io);
        },
    }
    b.installArtifact(exe);
}
