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

    const sayonara = "21ASDrtKfBL3Gx4TtkfBzZ";
    const melancholy = "0q6LuUqGLUiCPP1cbdwFs3";
    {
        // get a track by it's id
        const track = try zp.Track.getOne(alloc, c, sayonara, .{});
        printJson(track);
    }

    {
        // get tracks by their ids
        const tracks = try zp.Track.getMany(
            alloc,
            c,
            &.{ sayonara, melancholy },
            .{},
        );
        printJson(tracks);
    }

    {
        // get current user's tracks
        const tracks = try zp.Track.getSaved(alloc, c, .{});
        printJson(tracks);
    }

    {
        try zp.Track.remove(alloc, c, &.{ sayonara, melancholy });
        try zp.Track.save(alloc, c, &.{ sayonara, melancholy });
        const contains = try zp.Track.contains(alloc, c, &.{ sayonara, melancholy });

        printJson(contains);
    }
}
