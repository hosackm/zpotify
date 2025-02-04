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
    const hitch = "6yI0Np2UyigswnRqjSKN5V";
    const elton = "60nLqS5q761B0AJmTnPDbY";
    // Elton John: Me
    // https://open.spotify.com/show/60nLqS5q761B0AJmTnPDbY?si=61e14ea5061049b8

    {
        // get a single book by id
        _ = elton;
        const book = try zp.Audiobook.getOne(alloc, c, hitch, .{});
        defer book.deinit();
        try std.json.stringify(
            book.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    // {
    //     // get many books by id
    //     const books = try zp.Audiobook.getMany(alloc, c, &.{ hitch, elton }, .{});
    //     defer books.deinit();
    //     try std.json.stringify(
    //         books.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     // get chapters for a specific book
    //     _ = elton;
    //     const chapters = try zp.Audiobook.getChapters(alloc, c, hitch, .{});
    //     defer chapters.deinit();
    //     try std.json.stringify(
    //         chapters.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     // get the current user's saved books
    //     _ = elton;
    //     _ = hitch;
    //     const saved = try zp.Audiobook.getSaved(alloc, c, .{});
    //     defer saved.deinit();
    //     // try std.json.stringify(
    //     //     saved.value,
    //     //     .{},
    //     //     std.io.getStdOut().writer(),
    //     // );
    //     // _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     // add these books from current user's "saved"
    //     try zp.Audiobook.save(alloc, c, &.{ hitch, elton });
    // }

    // {
    //     // remove these books from current user's "saved"
    //     try zp.Audiobook.remove(alloc, c, &.{ hitch, elton });
    // }

    // {
    //     // check if the current user has saved the following books (by id)
    //     const saved = try zp.Audiobook.areSaved(alloc, c, &.{ hitch, elton });
    //     defer saved.deinit();
    //     try std.json.stringify(
    //         saved.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }
}
