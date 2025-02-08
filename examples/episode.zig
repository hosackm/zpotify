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

    const your_moms = "7pwe3F8sBnpf8NvqruLFrW";
    const bad_friends = "2dbSp6ewn5h3rXj1HqzyQE";
    {
        // get an episode by it's id
        const ep = try zp.Episode.getOne(alloc, c, your_moms, .{});
        defer ep.deinit();
        try std.json.stringify(
            ep.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    {
        // get episodes by their ids
        const episodes = try zp.Episode.getMany(
            alloc,
            c,
            &.{ your_moms, bad_friends },
            .{},
        );
        defer episodes.deinit();
        try std.json.stringify(
            episodes.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    // {
    //     // get current user's episodes
    //     const episodes = try zp.Episode.getSaved(alloc, c, .{});
    //     defer episodes.deinit();
    //     try std.json.stringify(
    //         episodes.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     try zp.Episode.save(alloc, c, &.{ your_moms, bad_friends });
    //     try zp.Episode.remove(alloc, c, &.{ your_moms, bad_friends });

    //     const contains = try zp.Episode.contains(alloc, c, &.{ your_moms, bad_friends });
    //     defer contains.deinit();

    //     try std.json.stringify(
    //         contains.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // list markets...
    // {
    //     const markets = try zp.Markets.list(alloc, c);
    //     defer markets.deinit();
    //     try std.json.stringify(
    //         markets.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }
}
