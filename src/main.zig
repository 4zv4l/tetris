const std = @import("std");
const ui = @import("ui.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);

    var board: ui.Board = undefined;
    @memset(&board, [_]u8{ ' ', '.' } ** (ui.cols / 2));

    try ui.init(bout.writer());
    try ui.drawBoard(bout.writer(), board);
    try bout.flush();
    std.time.sleep(std.time.ns_per_s * 5);

    try ui.deinit(bout.writer());
    try bout.flush();
}
