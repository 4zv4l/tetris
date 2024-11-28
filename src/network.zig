const std = @import("std");
const net = std.net;
const posix = std.posix;
const log = std.log;

const UDPServer = @This();
const Board = @import("root").Board;
const cols = @import("root").cols;
const rows = @import("root").rows;
pub const Clients = struct { board: Board, address: std.net.Address };

handle: posix.socket_t,

pub fn init(addr: net.Address) !UDPServer {
    const udp_server = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, 0);
    errdefer posix.close(udp_server);
    try posix.bind(udp_server, &addr.any, addr.getOsSockLen());
    return .{ .handle = udp_server };
}

pub fn deinit(self: UDPServer) void {
    posix.close(self.handle);
}

pub fn sendBoardToClients(self: UDPServer, clients: []Clients, board: Board) !void {
    for (clients) |client| {
        const client_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);
        _ = try posix.sendto(self.handle, &@as([rows * cols]u8, @bitCast(board)), 0, &client.address.any, client_addr_len);
    }
}

pub fn getBoardFromClients(self: UDPServer, clients: []Clients, mutex: *std.Thread.Mutex) !void {
    var board: [rows * cols]u8 = undefined;
    while (true) {
        var client_addr: net.Address = undefined;
        var client_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);
        _ = try posix.recvfrom(self.handle, &board, 0, &client_addr.any, &client_addr_len);
        for (clients) |*client| {
            if (net.Address.eql(client.address, client_addr)) {
                mutex.lock();
                client.board = @bitCast(board);
                mutex.unlock();
            }
        }
    }
}
