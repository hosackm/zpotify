const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    const result = try zp.Search.search(alloc, c, "boards of canada", .artist, .{});
    defer result.deinit();

    std.debug.print("result: {any}\n", .{result.value});
}
