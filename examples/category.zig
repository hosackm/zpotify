const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const TokenSource = @import("token.zig").TokenSource;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    const id = "dinner";
    {
        const category = try zp.Category.getOne(alloc, c, id, .{});
        defer category.deinit();
        try std.json.stringify(
            category.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().write("\n");
    }
    {
        const categories = try zp.Category.getMany(alloc, c, .{});
        defer categories.deinit();
        try std.json.stringify(
            categories.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().write("\n");
    }
}
