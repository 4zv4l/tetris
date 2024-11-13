const std = @import("std");
const ui = @import("ui.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);

    var board: ui.Board = undefined;
    @memset(&board, [_]u8{ ' ', '.' } ** (ui.cols / 2));

    // init
    try ui.init(bout.writer());
    defer {
        ui.deinit(bout.writer()) catch {};
        bout.flush() catch {};
    }
    try ui.drawBoard(bout.writer(), board);

    // main loop
    while (true) {
        // move current piece
        try bout.flush();
        std.Thread.sleep(std.time.ns_per_s * 1);
    }
}
