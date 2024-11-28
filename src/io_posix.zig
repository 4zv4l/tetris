const std = @import("std");
const spoon = @import("spoon");

const posix = std.posix;
const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const Shape = root.Shape;
const cols = root.cols;
const rows = root.rows;
const Client = root.Client;

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
var original_termios: posix.termios = undefined;

pub fn init() !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);
    try bout.writer().print("{s}", .{escape.ENTER_ALTER});
    try bout.flush();
    try term.init(.{});
    try term.uncook(.{});

    original_termios = try posix.tcgetattr(posix.STDIN_FILENO);
    var raw = original_termios;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.lflag.ISIG = false;
    raw.cc[@intFromEnum(posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(posix.V.TIME)] = 0;
    try posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.NOW, raw);
}

pub fn deinit() !void {
    original_termios.lflag.ICANON = true;
    try posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, original_termios);
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);
    try bout.writer().print("{s}{s}", .{ escape.CLEAR_TOP_LEFT, escape.EXIT_ALTER });
    try bout.flush();
    try term.cook();
    try term.deinit();
}

pub fn drawBoard(board: Board, clients: []Client) !void {
    const stdout = std.io.getStdOut().writer();
    var bout = std.io.bufferedWriter(stdout);

    // clear screen
    try bout.writer().print("{s}", .{"\x1b[2J\x1b[H"});

    var idx: usize = 0;
    try rawDrawBoard(bout.writer(), board, idx, null);
    for (clients) |client| {
        idx += ((cols * 2) + 8);
        try rawDrawBoard(bout.writer(), client.board, idx, client);
    }

    try bout.flush();
}

fn rawDrawBoard(writer: anytype, board: Board, x: usize, client: ?Client) !void {
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
    if (client) |c| {
        try writer.print("\r\n\n{s}host: {}\r\n{s}score: {d}", .{ move_tox, c.address, move_tox, c.score });
    } else {
        try writer.print("\r\n\n{s}host: {s}\r\n{s}score: {d}", .{ move_tox, "yourself", move_tox, root.lines_done });
    }
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
