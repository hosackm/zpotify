//! Markets from the web API reference
const std = @import("std");
const types = @import("types.zig");
const base_url = @import("url.zig").base_url;

const Markets = struct { markets: []const []const u8 };

pub fn list(alloc: std.mem.Allocator, client: anytype) !std.json.Parsed(Markets) {
    const body = try client.get(
        alloc,
        try std.Uri.parse(base_url ++ "/markets"),
    );
    defer alloc.free(body);
    return try std.json.parseFromSlice(
        Markets,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
