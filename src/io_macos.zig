const std = @import("std");
const ncurses = @cImport(@cInclude("ncurses.h"));

const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const Shape = root.Shape;
const cols = root.cols;
const Clients = root.Clients;

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

pub fn drawBoard(board: Board, clients: []Clients) !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);

    // clear screen
    try bout.writer().print("{s}", .{"\x1b[2J\x1b[H"});

    var idx: usize = 0;
    try rawDrawBoard(bout.writer(), board, idx);
    for (clients) |client| {
        idx += ((cols * 2) + 8);
        try rawDrawBoard(bout.writer(), client.board, idx);
    }

    try bout.flush();
    _ = ncurses.refresh();
}

fn rawDrawBoard(writer: anytype, board: Board, x: usize) !void {
    var buf: [10]u8 = undefined;
    const move_tox = try std.fmt.bufPrint(&buf, "\x1b[{d}C", .{x});

    try writer.print("\x1b[H", .{});

    // print board
    for (board) |line| {
        try writer.print("{s}{s}", .{ move_tox, left_border });
        for (line) |case| try writer.print("{s}", .{if (case == 0) empty else square});
        try writer.print("{s}\r\n", .{right_border});
    }

    // bottom of board
    try writer.print("{s}{s}", .{ move_tox, left_border });
    for (0..cols) |_| try writer.print("==", .{});
    try writer.print("{s}\r\n", .{right_border});
    try writer.print("{s}", .{move_tox});
    for (0..cols + 2) |_| try writer.print("/\\", .{});
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
