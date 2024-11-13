const std = @import("std");

pub const cols = 20;
pub const lines = 25;
pub const Board = [lines][cols]u8;

pub const left_border = "<!";
pub const right_border = "!>";
pub const square = "[]";

pub const escape = struct {
    const ENTER_ALTER = "\x1b[?1049h";
    const EXIT_ALTER = "\x1b[?1049l";
    const CLEAR_TOP_LEFT = "\x1b[2J\x1b[H";
    const SHOW_CURSOR = "\x1b[?25h";
    const HIDE_CURSOR = "\x1b[?25l";
};

pub fn init(writer: anytype) !void {
    try writer.print("{s}{s}", .{ escape.ENTER_ALTER, escape.HIDE_CURSOR });
}

pub fn deinit(writer: anytype) !void {
    try writer.print("{s}{s}", .{ escape.EXIT_ALTER, escape.SHOW_CURSOR });
}

pub fn drawBoard(writer: anytype, board: Board) !void {
    try writer.print("{s}", .{escape.CLEAR_TOP_LEFT});
    for (board) |line| {
        try writer.print("{s}", .{left_border});
        try writer.print("{s}", .{line});
        try writer.print("{s}\n", .{right_border});
    }
}
