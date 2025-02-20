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
        while (iter) |next| : (iter = try next.getNext(alloc, c)) {
            std.debug.print(
                "==== offset: {d}, limit: {d}, total: {d} ====\n",
                .{ next.offset, next.limit, next.total },
            );
            print(next);
        }
    }
}

fn print(v: zp.Paginated(zp.Track.Saved)) void {
    for (v.items) |saved| {
        std.debug.print("  {s} (by {s}), [added {s}]\n", .{
            saved.track.name[0..@min(saved.track.name.len, 50)],
            saved.track.artists[0].name[0..@min(saved.track.artists[0].name.len, 50)],
            saved.added_at,
        });
    }
}
