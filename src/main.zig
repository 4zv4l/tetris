// TODO: checkLines

const std = @import("std");
const io = @import("io.zig");
const rand = std.Random.DefaultPrng;

pub const cols = 10;
pub const rows = 20;
pub const Board = [rows][cols]u8;
pub const Direction = enum { Up, Down, Left, Right };

pub const Shape = struct {
    const shape_len = 3;

    array: [shape_len][shape_len]u8 = undefined,
    pos: struct { x: u8, y: u8 } = .{ .x = cols / 2, .y = 0 }, // top center

    const Shapes = &[_]Shape{
        .{ .array = .{
            .{ 0, 1, 1 },
            .{ 1, 1, 0 },
            .{ 0, 0, 0 },
        } }, // S
        .{ .array = .{
            .{ 1, 1, 0 },
            .{ 0, 1, 1 },
            .{ 0, 0, 0 },
        } }, // Z
        .{ .array = .{
            .{ 0, 1, 0 },
            .{ 1, 1, 1 },
            .{ 0, 0, 0 },
        } }, // T
        .{ .array = .{
            .{ 0, 0, 1 },
            .{ 1, 1, 1 },
            .{ 0, 0, 0 },
        } }, // L
        .{ .array = .{
            .{ 1, 0, 0 },
            .{ 1, 1, 1 },
            .{ 0, 0, 0 },
        } }, // rL
        .{ .array = .{
            .{ 1, 1, 0 },
            .{ 1, 1, 0 },
            .{ 0, 0, 0 },
        } }, // SQ
        .{ .array = .{
            .{ 0, 1, 0 },
            .{ 0, 1, 0 },
            .{ 0, 1, 0 },
        } }, // |
    };

    pub fn rotate90(self: *Shape) void {
        // cheating here for square
        if (std.mem.eql(u8, &@as([9]u8, @bitCast(self.array)), &@as([9]u8, @bitCast(Shapes[5].array)))) return;
        var result = Shape{};
        inline for (self.array, 0..) |line, line_idx| {
            inline for (line, 0..) |case, case_idx| {
                result.array[case_idx][result.array.len - line_idx - 1] = case;
            }
        }
        self.*.array = result.array;
    }

    pub fn newRandom() Shape {
        var rng = rand.init(@intCast(std.time.nanoTimestamp()));
        return Shapes[rng.random().uintLessThan(usize, Shapes.len)];
    }

    pub fn move(self: *Shape, direction: Direction, board: *Board, gameOn: *bool) void {
        deleteShapeFromBoard(self.*, board);
        var tmp: Shape = self.*;
        switch (direction) {
            .Up => {
                tmp.rotate90();
                if (checkPos(board.*, tmp)) self.rotate90();
            },
            .Down => {
                tmp.pos.y += 1;
                if (checkPos(board.*, tmp)) {
                    self.pos.y += 1;
                } else {
                    //checkLines(board);
                    updateBoard(board, self.*);
                    self.* = Shape.newRandom();
                    if (!checkPos(board.*, self.*)) gameOn.* = false;
                }
            },
            .Left => {
                tmp.pos.x -%= 1;
                if (checkPos(board.*, tmp)) {
                    self.pos.x -%= 1;
                }
            },
            .Right => {
                tmp.pos.x += 1;
                if (checkPos(board.*, tmp)) {
                    self.pos.x += 1;
                }
            },
        }
        updateBoard(board, self.*);
        try io.drawBoard(board.*, tmp);
    }
};

// check if piece overlap board active case
pub fn checkPos(board: Board, shape: Shape) bool {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if (shape.pos.x +% x_idx >= cols or board_y >= rows) {
                if (shape_case == 1) return false;
            } else if (shape_case == 1 and board[board_y][shape.pos.x +% x_idx] == 1) return false;
        }
    }
    return true;
}

pub fn deleteShapeFromBoard(shape: Shape, board: *Board) void {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if (shape_case == 1) board[board_y][shape.pos.x +% x_idx] = 0;
        }
    }
}

// update shape on board
pub fn updateBoard(board: *Board, shape: Shape) void {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if (shape_case == 1) board[board_y][shape.pos.x +% x_idx] = 1;
        }
    }
}

pub fn main() !void {
    // init IO
    try io.init();
    defer io.deinit() catch {};

    // setup vars
    var board: Board = std.mem.zeroes(Board);
    var gameOn = true;
    var current = Shape.newRandom();
    var before = std.time.nanoTimestamp();
    try io.drawBoard(board, current);

    // main loop
    while (gameOn) {
        // check user input
        if (io.getch()) |direction| current.move(direction, &board, &gameOn);

        // check time to move shape down
        const now = std.time.nanoTimestamp();
        if ((now - before) > (std.time.ns_per_s * 0.5)) {
            before = now;
            current.move(.Down, &board, &gameOn);
        }
    }
}
