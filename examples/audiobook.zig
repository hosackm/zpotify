const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

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
        printJson(chapters);
    }

    {
        // get the current user's saved books
        const saved = try zp.Audiobook.getSaved(alloc, c, .{});
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
        const saved = try zp.Audiobook.areSaved(
            alloc,
            c,
            &.{ hitch, elton },
        );
        printJson(saved);
    }
}
