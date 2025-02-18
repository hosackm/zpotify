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

    {
        const me = try zp.User.getCurrentUser(alloc, c);
        printJson(me);
    }

    {
        const top_artists = try zp.User.topArtists(alloc, c, .{});
        printJson(top_artists);
    }

    {
        const top_tracks = try zp.User.topTracks(alloc, c, .{});
        printJson(top_tracks);
    }

    {
        const friend = try zp.User.get(alloc, c, "misskristen");
        printJson(friend);
    }

    {
        // Kris's playlist - https://open.spotify.com/playlist/3CpnfLWptPPCyW3Mg6nCjv?si=ecrGtJQPQdC1SGOy4Ytfew
        const playlist_id = "3CpnfLWptPPCyW3Mg6nCjv";
        const result = try zp.User.isFollowingPlaylist(alloc, c, playlist_id);

        const is_following = result.resp.ok;
        if (is_following[0]) {
            std.debug.print("Was following, now unfollowing!\n", .{});
            try zp.User.unfollowPlaylist(alloc, c, playlist_id);
        } else {
            std.debug.print("Wasn't following, now following!\n", .{});
            try zp.User.followPlaylist(alloc, c, playlist_id, .{});
        }
    }

    {
        const artists = try zp.User.getFollowedArtists(alloc, c, .{});
        printJson(artists);
    }

    const nekrogoblikon = "3FILKvtNoiEfCJO9qVNCNF";
    const butcher_sisters = "6j8vGWE3wKAFEn0ngreusM";

    // follow/unfollow artists
    {
        try zp.User.followArtists(
            alloc,
            c,
            &.{ nekrogoblikon, butcher_sisters },
        );
        std.debug.print("Following both...\n", .{});

        try zp.User.unfollowArtists(
            alloc,
            c,
            &.{ nekrogoblikon, butcher_sisters },
        );
        std.debug.print("Unfollowing both...\n", .{});
    }

    {
        const json = try zp.User.isFollowingArtists(
            alloc,
            c,
            &.{ nekrogoblikon, butcher_sisters },
        );
        const is_following: []bool = json.resp.ok;

        std.debug.print(
            "Following?\n  Nekrogoblikon: {any}\n  Butcher Sisters: {any}\n",
            .{ is_following[0], is_following[1] },
        );
    }
}
