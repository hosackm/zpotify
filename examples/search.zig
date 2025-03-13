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

    // Simultaneously search for artist and tracks with "Snake" in the name.
    const result = try zp.Search.search(
        alloc,
        c,
        "Snake",
        .{
            .artist = true,
            .track = true,
        },
        .{},
    );
    defer result.deinit();
    switch (result.resp) {
        .ok => |res| {
            if (res.artists) |artists| {
                for (artists.items) |artist| {
                    std.debug.print("[artist]: {s}\n", .{artist.name});
                }
            }
            if (res.tracks) |tracks| {
                for (tracks.items) |track| {
                    std.debug.print("[track ]: {s}\n", .{track.name});
                }
            }
        },
        else => {},
    }

    // Perform artist, track, then album search
    const queries: []const struct { s: []const u8, type: zp.Search.Include } = &.{
        .{ .s = "boards of canada", .type = .{ .artist = true } },
        .{ .s = "ROYGBIV", .type = .{ .track = true } },
        .{ .s = "Music Has the Right to Children", .type = .{ .album = true } },
    };
    for (queries) |query| {
        const this_result = try zp.Search.search(
            alloc,
            c,
            query.s,
            query.type,
            .{},
        );
        defer this_result.deinit();

        const print = std.debug.print;
        switch (this_result.resp) {
            .ok => |res| {
                if (res.albums) |r| print("album: {s}\n", .{r.items[0].name});
                if (res.artists) |r| print("artist: {s}\n", .{r.items[0].name});
                if (res.audiobooks) |r| print("audiobooks: {s}\n", .{r.items[0].name});
                if (res.episodes) |r| print("episode: {s}\n", .{r.items[0].name});
                if (res.playlists) |r| print("playlist: {s}\n", .{r.items[0].name});
                if (res.shows) |r| print("show: {s}\n", .{r.items[0].name});
                if (res.tracks) |r| print("track: {s}\n", .{r.items[0].name});
            },
            .err => @panic("bad result returned from API"),
        }
    }
}
