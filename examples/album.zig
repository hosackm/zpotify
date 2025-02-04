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

    // const id = "4aawyAB9vmqN3uQ7FjRGTy"; // pitbull https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy?si=wgZeYibUQPy3Kx5tbNPVmA
    // const id = "3JK7UWkTqg4uyv2OfWRvQ9"; // franky baby https://open.spotify.com/album/3JK7UWkTqg4uyv2OfWRvQ9?si=Pd1M54m2SLeskzSb91DpWA
    // {
    //     const album = try zp.Album.getOne(
    //         alloc,
    //         client,
    //         id,
    //         .{},
    //     );
    //     defer album.deinit();
    //     try std.json.stringify(
    //         album.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const albums = try zp.Album.getMany(
    //         alloc,
    //         client,
    //         &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
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
    //     const tracks = try zp.Album.getTracks(
    //         alloc,
    //         client,
    //         "3JK7UWkTqg4uyv2OfWRvQ9",
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

    // {
    //     const saved = try zp.Album.getSaved(
    //         alloc,
    //         client,
    //         .{},
    //     );
    //     defer saved.deinit();
    //     try std.json.stringify(
    //         saved.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     try zp.Album.save(
    //         alloc,
    //         client,
    //         &.{"4aawyAB9vmqN3uQ7FjRGTy"},
    //     );
    //     std.debug.print("saved...\n", .{});

    //     std.debug.print("sleeping 0.5 seconds...\n", .{});
    //     std.time.sleep(std.time.ns_per_ms * 500);

    //     try zp.Album.delete(
    //         alloc,
    //         client,
    //         &.{"4aawyAB9vmqN3uQ7FjRGTy"},
    //     );
    //     std.debug.print("deleted...\n", .{});
    // }

    // {
    //     const checked = try zp.Album.check(
    //         alloc,
    //         client,
    //         &.{ "4aawyAB9vmqN3uQ7FjRGTy", "3JK7UWkTqg4uyv2OfWRvQ9" },
    //     );
    //     defer checked.deinit();
    //     try std.json.stringify(
    //         checked.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    {
        const new = try zp.Album.newReleases(
            alloc,
            client,
            .{},
        );
        defer new.deinit();
        try std.json.stringify(
            new.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().write("\n");
    }
}
