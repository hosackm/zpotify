const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    const sayonara = "21ASDrtKfBL3Gx4TtkfBzZ";
    const melancholy = "0q6LuUqGLUiCPP1cbdwFs3";
    {
        // get a track by it's id
        const track = try zp.Track.getOne(alloc, c, sayonara, .{});
        defer track.deinit();
        try printJson(track);
    }

    {
        // get tracks by their ids
        const tracks = try zp.Track.getMany(
            alloc,
            c,
            &.{ sayonara, melancholy },
            .{},
        );
        defer tracks.deinit();
        try printJson(tracks);
    }

    {
        // get current user's tracks
        const tracks = try zp.Track.getSaved(alloc, c, .{});
        defer tracks.deinit();
        try printJson(tracks);
    }

    {
        try zp.Track.remove(alloc, c, &.{ sayonara, melancholy });
        try zp.Track.save(alloc, c, &.{ sayonara, melancholy });
        const contains = try zp.Track.contains(alloc, c, &.{ sayonara, melancholy });
        defer contains.deinit();

        try printJson(contains);
    }
}
