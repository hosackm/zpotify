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

    const queries: []const struct { s: []const u8, type: zp.Search.Type } = &.{
        .{ .s = "boards of canada", .type = .artist },
        .{ .s = "ROYGBIV", .type = .track },
        .{ .s = "Music Has the Right to Children", .type = .album },
    };
    for (queries) |query| {
        const result = try zp.Search.search(
            alloc,
            c,
            query.s,
            query.type,
            .{},
        );

        const print = std.debug.print;
        switch (result.resp) {
            .ok => |res| {
                switch (res) {
                    .albums => |r| print("album: {s}\n", .{r.items[0].name}),
                    .artists => |r| print("artist: {s}\n", .{r.items[0].name}),
                    .audiobooks => |r| print("audiobook: {s}\n", .{r.items[0].name}),
                    .episodes => |r| print("episode: {s}\n", .{r.items[0].name}),
                    .playlists => |r| print("playlist: {s}\n", .{r.items[0].name}),
                    .shows => |r| print("show: {s}\n", .{r.items[0].name}),
                    .tracks => |r| print("track: {s}\n", .{r.items[0].name}),
                }
            },
            .err => @panic("bad result returned from API"),
        }
    }
}
