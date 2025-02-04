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

    // {
    //     const me = try zp.User.getCurrentUser(alloc, client);
    //     defer me.deinit();
    //     try std.json.stringify(
    //         me.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const top_artists = try zp.User.topArtists(alloc, client, .{});
    //     defer top_artists.deinit();
    //     try std.json.stringify(
    //         top_artists.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const top_tracks = try zp.User.topTracks(alloc, client, .{});
    //     defer top_tracks.deinit();
    //     try std.json.stringify(
    //         top_tracks.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     const friend = try zp.User.get(alloc, client, "misskristen");
    //     defer friend.deinit();
    //     try std.json.stringify(
    //         friend.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    // {
    //     // Kris's playlist - https://open.spotify.com/playlist/3CpnfLWptPPCyW3Mg6nCjv?si=ecrGtJQPQdC1SGOy4Ytfew
    //     const playlist_id = "3CpnfLWptPPCyW3Mg6nCjv";
    //     if (try zp.User.isFollowingPlaylist(alloc, client, playlist_id)) {
    //         try zp.User.unfollowPlaylist(alloc, client, playlist_id);
    //         std.debug.print("Was following, now unfollowing!\n", .{});
    //     } else {
    //         try zp.User.followPlaylist(alloc, client, playlist_id, .{});
    //         std.debug.print("Wasn't following, now following!\n", .{});
    //     }
    // }

    // {
    //     const artists = try zp.User.getFollowedArtists(alloc, client, .{});
    //     defer artists.deinit();
    //     try std.json.stringify(
    //         artists.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }

    const nekrogoblikon = "3FILKvtNoiEfCJO9qVNCNF";
    const butcher_sisters = "6j8vGWE3wKAFEn0ngreusM";

    // follow/unfollow artists
    // {
    //     try zp.User.followArtists(
    //         alloc,
    //         client,
    //         &.{ nekrogoblikon, butcher_sisters },
    //     );
    //     std.debug.print("Following both...\n", .{});

    //     try zp.User.unfollowArtists(
    //         alloc,
    //         client,
    //         &.{ nekrogoblikon, butcher_sisters },
    //     );
    //     std.debug.print("Unfollowing both...\n", .{});
    // }

    {
        const json = try zp.User.isFollowingArtists(
            alloc,
            client,
            &.{ nekrogoblikon, butcher_sisters },
        );
        defer json.deinit();
        const is_following = json.value;

        std.debug.print(
            "Following?\n  Nekrogoblikon: {any}\n  Butcher Sisters: {any}\n",
            .{ is_following[0], is_following[1] },
        );
    }
}
