const std = @import("std");
const spoon = @import("spoon");

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

var term: spoon.Term = undefined;

pub fn init() !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);
    try bout.writer().print("{s}", .{escape.ENTER_ALTER});
    try bout.flush();

    try term.init(.{});
    try term.uncook(.{});
}

pub fn deinit() !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);
    try bout.writer().print("{s}{s}", .{ escape.CLEAR_TOP_LEFT, escape.EXIT_ALTER });
    try bout.flush();
    try term.cook();
    try term.deinit();
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
    var buf: [16]u8 = undefined;
    const len = term.readInput(&buf) catch return null;
    var it = spoon.inputParser(buf[0..len]);
    while (it.next()) |in| {
        if (in.eqlDescription("w") or in.eqlDescription("arrow-up")) return .Up;
        if (in.eqlDescription("s") or in.eqlDescription("arrow-down")) return .Down;
        if (in.eqlDescription("a") or in.eqlDescription("arrow-left")) return .Left;
        if (in.eqlDescription("d") or in.eqlDescription("arrow-right")) return .Right;
        if (in.eqlDescription("q") or in.eqlDescription("C-c")) {
            deinit() catch {};
            std.process.exit(0);
        }
    }
    return null;
}
