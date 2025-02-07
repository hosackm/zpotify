//! Player from the web API reference

const std = @import("std");
const url = @import("url.zig");
const P = std.json.Parsed;

device: std.json.Value,
repeat_state: []const u8,
shuffle_state: bool,
context: ?std.json.Value,
timestamp: usize,
progress_ms: usize,
is_playing: bool,
// item: track or episode
currently_playing_type: []const u8, // track|episode|ad|unknown
actions: std.json.Value,

const Self = @This();

pub fn get(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, additional_types: ?[]const u8 = null },
) !?P(Self) {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player",
        null,
        .{ .market = opts.market, .additional_types = opts.additional_types },
    );
    defer alloc.free(player_url);

    const body = try client.get(alloc, try std.Uri.parse(player_url));
    defer alloc.free(body);

    return if (body.len > 0) try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    ) else null;
}
