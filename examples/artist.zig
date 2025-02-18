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
    const c = &client;

    const eno = "7MSUfLeTdDEoZiJPDSBXgi";
    const benson = "22wbnEMDvgVIAGdFeek6ET";
    {
        const artist = try zp.Artist.getOne(
            alloc,
            c,
            benson,
        );
        printJson(artist);
    }

    // Example of a bad request and how an error is returned.
    {
        const artist = try zp.Artist.getOne(
            alloc,
            c,
            "abcdeflkjgahsda", // bad id
        );
        printJson(artist);
    }

    {
        const artists = try zp.Artist.getMany(
            alloc,
            c,
            &.{ eno, "0TnOYISbd1XYRBk9myaseg" },
        );
        printJson(artists);
    }

    {
        const albums = try zp.Artist.getAlbums(
            alloc,
            c,
            eno,
            .{},
        );
        printJson(albums);
    }

    {
        const tracks = try zp.Artist.getTopTracks(
            alloc,
            c,
            eno,
            .{},
        );
        printJson(tracks);
    }
}
