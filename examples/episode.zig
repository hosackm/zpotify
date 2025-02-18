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

    const your_moms = "7pwe3F8sBnpf8NvqruLFrW";
    const bad_friends = "2dbSp6ewn5h3rXj1HqzyQE";
    {
        // get an episode by it's id
        const ep = try zp.Episode.getOne(alloc, c, your_moms, .{});
        printJson(ep);
    }

    {
        // get episodes by their ids
        const episodes = try zp.Episode.getMany(
            alloc,
            c,
            &.{ your_moms, bad_friends },
            .{},
        );
        printJson(episodes);
    }

    {
        // get current user's episodes
        const episodes = try zp.Episode.getSaved(alloc, c, .{});
        printJson(episodes);
    }

    {
        try zp.Episode.save(alloc, c, &.{ your_moms, bad_friends });
        try zp.Episode.remove(alloc, c, &.{ your_moms, bad_friends });

        const contains = try zp.Episode.contains(alloc, c, &.{ your_moms, bad_friends });

        printJson(contains);
    }
}
