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

    const bad_friends = "3gaGfrqgnVqUBNDdtv5p3S";
    // const your_moms = "7i59GubTw3CcNy9M6m7DTX";
    {
        // get a show by it's id
        const show = try zp.Show.getOne(alloc, c, bad_friends, .{});
        defer show.deinit();
        try std.json.stringify(
            show.value,
            .{},
            std.io.getStdOut().writer(),
        );
        _ = try std.io.getStdOut().writeAll("\n");
    }

    // {
    //     // get shows by their ids
    //     const shows = try zp.Show.getMany(
    //         alloc,
    //         c,
    //         &.{ your_moms, bad_friends },
    //         .{},
    //     );
    //     defer shows.deinit();
    //     try std.json.stringify(
    //         shows.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     // get shows by their ids
    //     const episodes = try zp.Show.getEpisodes(
    //         alloc,
    //         c,
    //         bad_friends,
    //         .{},
    //     );
    //     defer episodes.deinit();
    //     try std.json.stringify(
    //         episodes.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     // get current user's shows
    //     const shows = try zp.Show.getSaved(alloc, c, .{});
    //     defer shows.deinit();
    //     try std.json.stringify(
    //         shows.value,
    //         .{},
    //         std.io.getStdOut().writer(),
    //     );
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }

    // {
    //     try zp.Show.save(alloc, c, &.{ your_moms, bad_friends });
    //     try zp.Show.remove(alloc, c, &.{ your_moms, bad_friends });

    //     const contains = try zp.Show.contains(alloc, c, &.{ your_moms, bad_friends });
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
