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

    const eno = "7MSUfLeTdDEoZiJPDSBXgi";
    const benson = "22wbnEMDvgVIAGdFeek6ET";
    {
        const artist = try zp.Artist.getOne(
            alloc,
            c,
            benson,
        );
        defer artist.deinit();
        printJson(artist);
    }

    // Example of a bad request and how an error is returned.
    {
        const artist = try zp.Artist.getOne(
            alloc,
            c,
            "abcdeflkjgahsda", // bad id
        );
        defer artist.deinit();
        printJson(artist);
    }

    {
        const artists = try zp.Artist.getMany(
            alloc,
            c,
            &.{ eno, "0TnOYISbd1XYRBk9myaseg" },
        );
        defer artists.deinit();
        printJson(artists);
    }

    {
        const albums = try zp.Artist.getAlbums(
            alloc,
            c,
            eno,
            .{},
        );
        defer albums.deinit();
        printJson(albums);
    }

    {
        const tracks = try zp.Artist.getTopTracks(
            alloc,
            c,
            eno,
            .{},
        );
        defer tracks.deinit();
        printJson(tracks);
    }
}
