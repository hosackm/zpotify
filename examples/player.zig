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

    {
        // get a playlist by it's id
        if (try zp.Player.get(alloc, c, .{})) |player| {
            defer player.deinit();
            try std.json.stringify(
                player.value,
                .{},
                std.io.getStdOut().writer(),
            );
        } else {
            _ = try std.io.getStdOut().writeAll("null");
        }
        _ = try std.io.getStdOut().writeAll("\n");
    }
}
