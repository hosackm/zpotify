const std = @import("std");
const zp = @import("zpotify");
const TokenSource = @import("token.zig").TokenSource;
const Client = @import("client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    // Hitchiker's Guide
    // https://open.spotify.com/show/6yI0Np2UyigswnRqjSKN5V?si=bbd3a9c44f4e4d41
    const one = "4P3b73KGNxOZHIDFTKRLoT";
    // const another = "5zD0AIMbpgCZgY56JSYhYl";

    {
        // get a chapter by it's id
        const chapter = try zp.Chapter.getOne(alloc, c, one, .{});
        defer chapter.deinit();
        try std.json.stringify(
            chapter.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    // {
    //     // get multiple chapters by their ids
    //     const chapters = try zp.Chapter.getMany(alloc, c, &.{ one, another }, .{});
    //     defer chapters.deinit();
    //     try std.json.stringify(
    //         chapters.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }
}
