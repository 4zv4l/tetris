const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));

const root = @import("root");
const Board = root.Board;
const Direction = root.Direction;
const Shape = root.Shape;
const cols = root.cols;
const rows = root.rows;
const square_size = 20;

pub fn init() !void {
    rl.InitWindow(cols * square_size, rows * square_size, "Tetris");
}

pub fn deinit() !void {
    rl.CloseWindow();
}

pub fn drawBoard(board: Board, _: Shape) !void {
    rl.BeginDrawing();

    rl.ClearBackground(rl.RAYWHITE);

    var x: c_int = 0;
    var y: c_int = 0;
    for (board) |line| {
        for (line) |case| {
            const color = if (case == 1) rl.BLACK else rl.WHITE;
            rl.DrawRectangle(x, y, square_size, square_size, color);
            x += square_size;
        }
        x = 0;
        y += square_size;
    }

    rl.EndDrawing();
}

pub fn getch() ?Direction {
    if (rl.WindowShouldClose()) {
        try deinit();
        std.process.exit(0);
    }
    return switch (rl.GetKeyPressed()) {
        rl.KEY_W, rl.KEY_UP => .Up,
        rl.KEY_S, rl.KEY_DOWN => .Down,
        rl.KEY_A, rl.KEY_LEFT => .Left,
        rl.KEY_D, rl.KEY_RIGHT => .Right,
        else => null,
    };
}
