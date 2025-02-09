const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    const playlist_id = "1LyBnDxdG9CdJ8be4SrmOU";
    // {
    //     // get a playlist by it's id
    //     const playlist = try zp.Playlist.getOne(alloc, c, playlist_id, .{});
    //     defer playlist.deinit();
    //     try std.json.stringify(
    //         playlist.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }
    {
        // get a playlist tracks
        const tracks = try zp.Playlist.getTracks(alloc, c, playlist_id, .{});
        defer tracks.deinit();
        try std.json.stringify(
            tracks.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    // {
    //     // change the details of a playlist
    //     var buffer: [128]u8 = undefined;
    //     const description_str = try std.fmt.bufPrint(
    //         &buffer,
    //         "Updated description. Value: {d}",
    //         .{std.time.nanoTimestamp()},
    //     );
    //     std.debug.print("setting playlist description to: {s}\n", .{description_str});

    //     try zp.Playlist.setDetails(
    //         alloc,
    //         c,
    //         "0pG5NJccBHQOUj3ihujaxo",
    //         .{ .description = description_str },
    //     );
    // }

    // {
    //     // get current user's tracks
    //     const tracks = try zp.Track.getSaved(alloc, c, .{});
    //     defer tracks.deinit();
    //     try std.json.stringify(
    //         tracks.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     try zp.Track.remove(alloc, c, &.{ sayonara, melancholy });
    //     try zp.Track.save(alloc, c, &.{ sayonara, melancholy });
    //     const contains = try zp.Track.contains(alloc, c, &.{ sayonara, melancholy });
    //     defer contains.deinit();

    //     try std.json.stringify(
    //         contains.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     const playlist = try zp.Playlist.saved(alloc, c, .{});
    //     defer playlist.deinit();
    //     try std.json.stringify(
    //         playlist.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }
    // {
    //     const playlist = try zp.Playlist.getPlaylistsForUser(alloc, c, "hosackm", .{});
    //     defer playlist.deinit();
    //     try std.json.stringify(
    //         playlist.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().write("\n");
    // }
}
