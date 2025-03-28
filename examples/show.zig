const std = @import("std");
const zp = @import("zpotify");
const buildClient = @import("client.zig").buildClient;
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const alloc = gpa.allocator();

    var client = try buildClient(alloc);
    defer client.deinit();
    const c = &client;

    const bad_friends = "3gaGfrqgnVqUBNDdtv5p3S";
    const your_moms = "7i59GubTw3CcNy9M6m7DTX";
    {
        // get a show by it's id
        const show = try zp.Show.getOne(alloc, c, bad_friends, .{});
        defer show.deinit();
        printJson(show);
    }

    {
        // get shows by their ids
        const shows = try zp.Show.getMany(
            alloc,
            c,
            &.{ your_moms, bad_friends },
            .{},
        );
        defer shows.deinit();
        printJson(shows);
    }

    {
        // get shows by their ids
        const episodes = try zp.Show.getEpisodes(
            alloc,
            c,
            bad_friends,
            .{},
        );
        defer episodes.deinit();
        printJson(episodes);
    }

    {
        // get current user's shows
        const shows = try zp.Show.getSaved(alloc, c, .{});
        defer shows.deinit();
        printJson(shows);
    }

    {
        try zp.Show.save(alloc, c, &.{ your_moms, bad_friends });
        try zp.Show.remove(alloc, c, &.{ your_moms, bad_friends });

        const contains = try zp.Show.contains(alloc, c, &.{ your_moms, bad_friends });
        defer contains.deinit();
        printJson(contains);
    }

    // list markets...
    {
        const markets = try zp.Markets.list(alloc, c);
        defer markets.deinit();
        printJson(markets);
    }
}
