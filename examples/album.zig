const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    const id = "3JK7UWkTqg4uyv2OfWRvQ9";
    {
        const album = try zp.Album.getOne(
            alloc,
            c,
            id,
            .{},
        );
        defer album.deinit();
        printJson(album);
    }

    {
        const albums = try zp.Album.getMany(
            alloc,
            c,
            &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
            .{},
        );
        defer albums.deinit();
        printJson(albums);
    }

    {
        const tracks = try zp.Album.getTracks(
            alloc,
            c,
            "3JK7UWkTqg4uyv2OfWRvQ9",
            .{},
        );
        defer tracks.deinit();
        printJson(tracks);
    }

    {
        const saved = try zp.Album.getSaved(
            alloc,
            c,
            .{},
        );
        defer saved.deinit();
        printJson(saved);
    }

    {
        try zp.Album.save(
            alloc,
            c,
            &.{"4aawyAB9vmqN3uQ7FjRGTy"},
        );
        std.debug.print("saved...\n", .{});

        std.debug.print("sleeping 0.5 seconds...\n", .{});
        std.time.sleep(std.time.ns_per_ms * 500);

        try zp.Album.delete(
            alloc,
            c,
            &.{"4aawyAB9vmqN3uQ7FjRGTy"},
        );
        std.debug.print("deleted...\n", .{});
    }

    {
        const contains = try zp.Album.contains(
            alloc,
            c,
            &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
        );
        defer contains.deinit();
        printJson(contains);
    }

    {
        const new = try zp.Album.newReleases(
            alloc,
            c,
            .{},
        );
        defer new.deinit();
        printJson(new);
    }
}
