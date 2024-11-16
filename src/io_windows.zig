const std = @import("std");
const conio = @cImport(@cInclude("conio.h"));

const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const Shape = root.Shape;
const cols = root.cols;

pub const left_border = "<!";
pub const right_border = "!>";
pub const square = "[]";
pub const empty = ". ";

pub const escape = struct {
    const ENTER_ALTER = "\x1b[?1049h";
    const EXIT_ALTER = "\x1b[?1049l";
    const CLEAR_TOP_LEFT = "\x1b[2J\x1b[H";
    const SHOW_CURSOR = "\x1b[?25h";
    const HIDE_CURSOR = "\x1b[?25l";
};

pub fn init() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}", .{escape.ENTER_ALTER});
}

pub fn deinit() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}", .{escape.EXIT_ALTER});
}

pub fn drawBoard(board: Board, _: Shape) !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);

    // clear screen
    try bout.writer().print("{s}", .{"\x1b[2J\x1b[H"});

    // print board
    for (board) |line| {
        try bout.writer().print("{s}", .{left_border});
        for (line) |case| try bout.writer().print("{s}", .{if (case == 0) empty else square});
        try bout.writer().print("{s}\r\n", .{right_border});
    }

    // bottom of board
    try bout.writer().print("{s}", .{left_border});
    for (0..cols) |_| try bout.writer().print("==", .{});
    try bout.writer().print("{s}\r\n", .{right_border});
    for (0..cols + 2) |_| try bout.writer().print("/\\", .{});

    try bout.flush();
}

pub fn getch() ?Direction {
    if (conio._kbhit() > 0) {
        return switch (conio._getch()) {
            'w' => .Up,
            's' => .Down,
            'a' => .Left,
            'd' => .Right,
            0, 224 => switch (conio._getch()) {
                72 => .Up,
                80 => .Down,
                75 => .Left,
                77 => .Right,
                else => null,
            },
            else => null,
        };
    }
    return null;
}
