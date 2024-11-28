const std = @import("std");
const rand = std.Random.DefaultPrng;
const io = @import("io");
const UDPServer = @import("network.zig");
pub const Clients = UDPServer.Clients;

pub const cols = 10;
pub const rows = 20;
pub var lines_done: usize = 0;
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

    pub fn move(self: *Shape, direction: Direction, board: *Board, gameOn: *bool) !void {
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
                    updateBoard(board, self.*);
                    checkLines(board);
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
                tmp.pos.x +|= 1;
                if (checkPos(board.*, tmp)) {
                    self.pos.x += 1;
                }
            },
        }
        updateBoard(board, self.*);
    }
};

pub fn checkLines(board: *Board) void {
    var line_idx: usize = 0;
    while (line_idx < board.len) : (line_idx += 1) {
        if (std.mem.eql(u8, &board[line_idx], &[_]u8{1} ** cols)) {
            var current_line: usize = line_idx;
            while (current_line > 0) : (current_line -= 1) {
                board[current_line] = board[current_line - 1];
            }
            @memset(&board[0], 0);
            line_idx = 0;
            lines_done += 1;
        }
    }
}

// check if piece overlap board active case
pub fn checkPos(board: Board, shape: Shape) bool {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if ((shape.pos.x +% @as(u8, @intCast(x_idx)) >= cols or board_y >= rows) and shape_case == 1) {
                return false;
            } else if (shape_case == 1 and board[board_y][shape.pos.x +% @as(u8, @intCast(x_idx))] == 1) return false;
        }
    }
    return true;
}

pub fn deleteShapeFromBoard(shape: Shape, board: *Board) void {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if (shape_case == 1) board[board_y][shape.pos.x +% @as(u8, @intCast(x_idx))] = 0;
        }
    }
}

// update shape on board
pub fn updateBoard(board: *Board, shape: Shape) void {
    for (shape.array, shape.pos.y..shape.pos.y + 3) |shape_line, board_y| {
        for (shape_line, 0..) |shape_case, x_idx| {
            if (shape_case == 1) board[board_y][shape.pos.x +% @as(u8, @intCast(x_idx))] = 1;
        }
    }
}

// parse ip:port
fn parseIp(host: []const u8) !std.net.Address {
    var host_it = std.mem.splitScalar(u8, host, ':');
    const ip = host_it.next() orelse @panic("wrong address given in arguments");
    const strport = host_it.next() orelse @panic("wrong address given in arguments");
    const port = try std.fmt.parseUnsigned(u16, strport, 10);
    return try std.net.Address.parseIp(ip, port);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // setup server and thread if required
    var udp_server: ?UDPServer = null;
    var clients: ?[]Clients = null;
    var client_mutex = std.Thread.Mutex{};
    switch (args.len) {
        0, 1, 2 => {},
        else => {
            udp_server = try UDPServer.init(try parseIp(args[1]));
            clients = try allocator.alloc(Clients, args.len - 2);
            errdefer allocator.free(clients.?);
            for (args[2..], clients.?) |strhost, *client| client.* = .{ .address = try parseIp(strhost) };
            var t = try std.Thread.spawn(.{}, UDPServer.getBoardFromClients, .{ udp_server.?, clients.?, &client_mutex });
            t.detach();
        },
    }
    defer {
        if (clients) |cs| allocator.free(cs);
        if (udp_server) |server| server.deinit();
    }

    // init IO
    try io.init();
    defer io.deinit() catch {};

    // setup vars
    var board: Board = std.mem.zeroes(Board);
    var gameOn = true;
    var current = Shape.newRandom();
    var before = std.time.nanoTimestamp();
    var speed: f64 = 0.5;
    try io.drawBoard(board, clients orelse &.{});

    // main loop
    while (gameOn) {
        // check user input
        if (io.getch()) |direction| {
            try current.move(direction, &board, &gameOn);
            if (udp_server) |server| try server.sendBoardToClients(clients.?, board);
            client_mutex.lock();
            try io.drawBoard(board, clients orelse &.{});
            client_mutex.unlock();
        }

        // check time to move shape down
        const now = std.time.nanoTimestamp();
        if ((now - before) > @as(i128, @intFromFloat(std.time.ns_per_s * speed))) {
            speed = switch (lines_done) {
                0...5 => 0.5,
                6...10 => 0.4,
                11...15 => 0.3,
                16...20 => 0.2,
                else => 0.1,
            };
            before = now;
            if (udp_server) |server| try server.sendBoardToClients(clients.?, board);
            try current.move(.Down, &board, &gameOn);
            client_mutex.lock();
            try io.drawBoard(board, clients orelse &.{});
            client_mutex.unlock();
        }
    }
}
