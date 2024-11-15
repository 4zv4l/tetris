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
}

pub fn deinit() !void {
    _ = ncurses.endwin();
}

pub fn drawBoard(board: Board, current: Shape) !void {
    // clear screen
    _ = ncurses.clear();
    _ = ncurses.refresh();

    // print board
    for (board) |line| {
        _ = ncurses.printf("%s", left_border);
        for (line) |case| _ = ncurses.printf("%s", if (case == 0) empty else square);
        _ = ncurses.printf("%s\r\n", right_border);
    }
    // bottom of board
    _ = ncurses.printf("%s", left_border);
    for (0..cols) |_| _ = ncurses.printf("==");
    _ = ncurses.printf("%s\r\n", right_border);
    for (0..cols + 2) |_| _ = ncurses.printf("/\\");

    _ = ncurses.printf("\r\n\r\n(%d, %d)", current.pos.x, current.pos.y);
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
