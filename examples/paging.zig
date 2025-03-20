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

    // In order to page a single entity, you must use its provided getNext() method.
    // This method will return an optional next page. If there is no next page
    // then null will be returned. The same is true for getPrevious(), which will
    // return the previous page of entities.
    const result = try zp.Track.getSaved(alloc, c, .{});
    if (result.resp == .ok) {
        var iter: ?@TypeOf(result.resp.ok) = result.resp.ok;
        // page forward 3 times
        var num: usize = 0;
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

    // Paging a Search Result is different because the Spotify Search API treats
    // search results differently. A Result contains results for all types of
    // resources in the same structure (ie. tracks, albums, episodes etc.)
    //
    // The user must specify which entity should be paged when calling
    // pageForward().  If the page is successful the corresponding data will be
    // updated in place in the Result structure and true will be returned from
    // the function call.
    const search_response = try zp.Search.search(
        alloc,
        c,
        "love",
        .{ .track = true },
        .{},
    );
    if (search_response.resp == .err) @panic("error returned from search");

    var searched = search_response.resp.ok;
    printPage(searched.tracks.?);

    if (try searched.pageForward(alloc, c, .tracks)) {
        // page backward, should be the same tracks as the first print
        printPage(searched.tracks.?);
        _ = try searched.pageBackward(alloc, c, .tracks);
        printPage(searched.tracks.?);
    }
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
