const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const common = @import("common.zig");
const printJson = common.printJson;
const parseEnvFile = common.parseEnvFile;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client;

    const id = "3JK7UWkTqg4uyv2OfWRvQ9";
    {
        const album = try zp.Album.getOne(
            alloc,
            c,
            id,
            .{},
        );
        printJson(album);
    }

    {
        const albums = try zp.Album.getMany(
            alloc,
            c,
            &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
            .{},
        );
        printJson(albums);
    }

    {
        const tracks = try zp.Album.getTracks(
            alloc,
            c,
            "3JK7UWkTqg4uyv2OfWRvQ9",
            .{},
        );
        printJson(tracks);
    }

    {
        const saved = try zp.Album.getSaved(
            alloc,
            c,
            .{},
        );
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

        try zp.Album.remove(
            alloc,
            c,
            &.{"4aawyAB9vmqN3uQ7FjRGTy"},
        );
        std.debug.print("removed...\n", .{});
    }

    {
        const contains = try zp.Album.contains(
            alloc,
            c,
            &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
        );
        printJson(contains);
    }

    {
        const new = try zp.Album.newReleases(
            alloc,
            c,
            .{},
        );
        printJson(new);
    }
}
