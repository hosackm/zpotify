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

    const result = try zp.Track.getSaved(alloc, c, .{});
    if (result.resp == .ok) {
        var iter: ?@TypeOf(result.resp.ok) = result.resp.ok;
        var num: usize = 0;

        // page forward 3 times
        while (num < 3) : (num += 1) {
            if (iter) |next| {
                std.debug.print(
                    "==== offset: {d}, limit: {d}, total: {d} ====\n",
                    .{ next.offset, next.limit, next.total },
                );
                printSaved(next);
                iter = try next.getNext(alloc, c);
            } else break;
        }

        // page backwards 3 times
        while (num > 0) : (num -= 1) {
            if (iter) |prev| {
                std.debug.print(
                    "==== offset: {d}, limit: {d}, total: {d} ====\n",
                    .{ prev.offset, prev.limit, prev.total },
                );
                printSaved(prev);
                iter = try prev.getPrevious(alloc, c);
            } else break;
        }
    }

    // const search_response = try zp.Search.search(
    //     alloc,
    //     c,
    //     "love",
    //     .{ .track = true },
    //     .{},
    // );
    // if (search_response.resp == .err) @panic("error returned from search");

    // var searched = search_response.resp.ok;
    // printPage(searched.tracks.?);

    // if (try searched.pageForward(alloc, c, .tracks)) {
    //     // page backward, should be the same tracks as the first print
    //     printPage(searched.tracks.?);
    //     _ = try searched.pageBackward(alloc, c, .tracks);
    //     printPage(searched.tracks.?);
    // }
}

fn printSaved(v: zp.Paginated(zp.Track.Saved)) void {
    for (v.items) |saved| {
        std.debug.print("  {s} (by {s}), [added {s}]\n", .{
            saved.track.name[0..@min(saved.track.name.len, 50)],
            saved.track.artists[0].name[0..@min(saved.track.artists[0].name.len, 50)],
            saved.added_at,
        });
    }
}

fn printPage(v: zp.Paginated(zp.Track.Simple)) void {
    for (v.items, v.offset + 1..) |track, i| {
        std.debug.print("[{d}] {s}\n", .{ i, track.name });
    }
}
