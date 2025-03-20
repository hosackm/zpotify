const std = @import("std");
const zp = @import("zpotify");
const buildClient = @import("client.zig").buildClient;
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const alloc = gpa.allocator();

    var client = try buildClient(alloc);
    defer client.deinit();
    const c = &client;

    const hitch = "6yI0Np2UyigswnRqjSKN5V";
    const elton = "60nLqS5q761B0AJmTnPDbY";

    {
        // get a single book by id
        const book = try zp.Audiobook.getOne(
            alloc,
            c,
            hitch,
            .{},
        );
        defer book.deinit();
        printJson(book);
    }

    {
        // get many books by id
        const books = try zp.Audiobook.getMany(
            alloc,
            c,
            &.{ hitch, elton },
            .{},
        );
        defer books.deinit();
        printJson(books);
    }

    {
        // get chapters for a specific book
        const chapters = try zp.Audiobook.getChapters(
            alloc,
            c,
            hitch,
            .{},
        );
        defer chapters.deinit();
        printJson(chapters);
    }

    {
        // get the current user's saved books
        const saved = try zp.Audiobook.getSaved(alloc, c, .{});
        defer saved.deinit();
        printJson(saved);
    }

    {
        // add these books from current user's "saved"
        try zp.Audiobook.save(alloc, c, &.{ hitch, elton });
    }

    {
        // remove these books from current user's "saved"
        try zp.Audiobook.remove(alloc, c, &.{ hitch, elton });
    }

    {
        // check if the current user has saved the following books (by id)
        const saved = try zp.Audiobook.contains(
            alloc,
            c,
            &.{ hitch, elton },
        );
        defer saved.deinit();
        printJson(saved);
    }
}
