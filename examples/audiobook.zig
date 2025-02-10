const std = @import("std");
const zp = @import("zpotify");
const TokenSource = @import("token.zig").TokenSource;
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
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
        defer book.deinit();
        try printJson(book);
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
        try printJson(books);
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
        try printJson(chapters);
    }

    {
        // get the current user's saved books
        const saved = try zp.Audiobook.getSaved(alloc, c, .{});
        defer saved.deinit();
        try printJson(saved);
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
        defer saved.deinit();
        try printJson(saved);
    }
}
