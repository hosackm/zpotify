//! Genres from the web API reference
const std = @import("std");
const types = @import("types.zig");
const base_url = @import("urls.zig").base_url;

const Genres = struct { genres: []const []const u8 };

// Deprecated
// pub fn list(alloc: std.mem.Allocator, client: anytype) !std.json.Parsed(Genres) {
//     const body = try client.get(
//         alloc,
//         try std.Uri.parse(base_url ++ "/recommendations/available-genre-seeds"),
//     );
//     defer alloc.free(body);

//     return try std.json.parseFromSlice(Genres, alloc, body, .{});
// }
