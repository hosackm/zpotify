const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const TokenSource = @import("token.zig").TokenSource;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    // 7MSUfLeTdDEoZiJPDSBXgi - brian eno
    // 0TnOYISbd1XYRBk9myaseg - pitbull
    // {
    //     const artist = try zp.Artist.getOne(
    //         alloc,
    //         c,
    //         "22wbnEMDvgVIAGdFeek6ET",
    //     );
    //     defer artist.deinit();
    //     try std.json.stringify(
    //         artist.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const artists = try zp.Artist.getMany(
    //         alloc,
    //         c,
    //         &.{ "7MSUfLeTdDEoZiJPDSBXgi", "0TnOYISbd1XYRBk9myaseg" },
    //     );
    //     defer artists.deinit();

    //     try std.json.stringify(
    //         artists.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const albums = try zp.Artist.getAlbums(
    //         alloc,
    //         c,
    //         "7MSUfLeTdDEoZiJPDSBXgi",
    //         .{},
    //     );
    //     defer albums.deinit();

    //     try std.json.stringify(
    //         albums.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    {
        const tracks = try zp.Artist.getTopTracks(
            alloc,
            c,
            "7MSUfLeTdDEoZiJPDSBXgi",
            .{},
        );
        defer tracks.deinit();

        try std.json.stringify(
            tracks.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().write("\n");
    }
}
