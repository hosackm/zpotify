const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const alloc = gpa.allocator();

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client;

    // test playlist with mixture of tracks/episodes
    const playlist_id = "1yRKZ71iI78RiATBdg1OQK";
    {
        // get a playlist by it's id
        const playlist = try zp.Playlist.getOne(alloc, c, playlist_id, .{});
        defer playlist.deinit();
        printJson(playlist);
    }

    {
        // get a playlist's tracks
        const tracks = try zp.Playlist.getTracks(
            alloc,
            c,
            playlist_id,
            .{},
        );
        defer tracks.deinit();
        printJson(tracks);
    }

    {
        // change the details of a playlist
        var buffer: [128]u8 = undefined;
        const description_str = try std.fmt.bufPrint(
            &buffer,
            "Updated description. Value: {d}",
            .{std.time.nanoTimestamp()},
        );
        std.debug.print("setting playlist description to: {s}\n", .{description_str});

        try zp.Playlist.setDetails(
            alloc,
            c,
            "0pG5NJccBHQOUj3ihujaxo",
            .{ .description = description_str },
        );
    }

    {
        const playlist = try zp.Playlist.saved(alloc, c, .{});
        defer playlist.deinit();
        printJson(playlist);
    }
    {
        const playlist = try zp.Playlist.getPlaylistsForUser(alloc, c, "hosackm", .{});
        defer playlist.deinit();
        printJson(playlist);
    }
}
