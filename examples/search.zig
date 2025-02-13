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
        defer result.deinit();

        switch (result.resp) {
            .ok => printJson(result),
            .err => {},
        }
    }
}
