const std = @import("std");
const ncurses = @cImport(@cInclude("ncurses.h"));

const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const cols = root.cols;

pub const left_border = "<!";
pub const right_border = "!>";
pub const square = "[]";

pub fn init() !void {
    _ = ncurses.initscr();
    _ = ncurses.cbreak();
    _ = ncurses.noecho();
    _ = ncurses.nodelay(ncurses.stdscr, true);
}

pub fn deinit() !void {
    _ = ncurses.endwin();
}

pub fn drawBoard(board: Board) !void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    for (board) |line| {
        _ = ncurses.printf("%s", left_border);
        for (line) |case| _ = ncurses.printf("%s", if (case == 0) " ." else "[]");
        _ = ncurses.printf("%s\r\n", right_border);
    }
    _ = ncurses.printf("%s", left_border);
    for (0..cols) |_| _ = ncurses.printf("==");
    _ = ncurses.printf("%s\r\n", right_border);
    for (0..cols + 2) |_| _ = ncurses.printf("/\\");
    _ = ncurses.refresh();
}

pub fn getch() ?Direction {
    return switch (ncurses.getch()) {
        'w' => .Up,
        's' => .Down,
        'a' => .Left,
        'd' => .Right,
        else => null,
    };
}
