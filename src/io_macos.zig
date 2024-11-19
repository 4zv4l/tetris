const std = @import("std");
const ncurses = @cImport(@cInclude("ncurses.h"));

const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const Shape = root.Shape;
const cols = root.cols;

pub const left_border = "<!";
pub const right_border = "!>";
pub const square = "[]";
pub const empty = ". ";

pub fn init() !void {
    _ = ncurses.initscr();
    _ = ncurses.cbreak();
    _ = ncurses.noecho();
    _ = ncurses.nodelay(ncurses.stdscr, true);
    _ = ncurses.keypad(ncurses.stdscr, true);
}

pub fn deinit() !void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    _ = ncurses.endwin();
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
    _ = ncurses.refresh();
}

pub fn getch() ?Direction {
    return switch (ncurses.getch()) {
        'w', ncurses.KEY_UP => .Up,
        's', ncurses.KEY_DOWN => .Down,
        'a', ncurses.KEY_LEFT => .Left,
        'd', ncurses.KEY_RIGHT => .Right,
        else => null,
    };
}
