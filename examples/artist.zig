const std = @import("std");
const zp = @import("zpotify");
const TokenSource = @import("token.zig").TokenSource;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var em = try std.process.getEnvMap(alloc);
    defer em.deinit();

    const AuthType = zp.Authenticator(TokenSource);

    var auth = AuthType.init(.{
        .token_source = .{
            .filename = ".token.json",
            .allocator = alloc,
        },
        .credentials = .{
            .redirect_uri = em.get("SPOTIFY_REDIRECT").?,
            .client_id = em.get("SPOTIFY_ID").?,
            .client_secret = em.get("SPOTIFY_SECRET").?,
        },
        .allocator = alloc,
    });

    const ClientType = zp.Client(zp.Authenticator(TokenSource));
    const client = ClientType{
        .authenticator = &auth,
    };

    // 7MSUfLeTdDEoZiJPDSBXgi - brian eno
    // 0TnOYISbd1XYRBk9myaseg - pitbull
    {
        const artist = try zp.Artist.getOne(
            alloc,
            client,
            "22wbnEMDvgVIAGdFeek6ET",
        );
        defer artist.deinit();
        try std.json.stringify(
            artist.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().write("\n");
    }

    // {
    //     const artists = try zp.Artist.getMany(
    //         alloc,
    //         client,
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
    //         client,
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

    // {
    //     const tracks = try zp.Artist.getTopTracks(
    //         alloc,
    //         client,
    //         "7MSUfLeTdDEoZiJPDSBXgi",
    //         .{},
    //     );
    //     defer tracks.deinit();

    //     try std.json.stringify(
    //         tracks.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }
}
