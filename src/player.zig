//! Player from the web API reference
const std = @import("std");
const url = @import("url.zig");
const types = @import("types.zig");
const P = std.json.Parsed;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

timestamp: usize,
context: ?std.json.Value,
progress_ms: usize,
currently_playing_type: []const u8, // track|episode|ad|unknown
actions: std.json.Value,
is_playing: bool,

// not returned in json when testing
device: ?Device = null,
// repeat_state: ?[]const u8 = null,
// item: ?track or episod = nulle
// shuffle_state: ?bool = null,

const Self = @This();

pub const Device = struct {
    id: []const u8,
    is_active: bool,
    is_private_session: ?bool = null,
    is_restricted: ?bool = null,
    name: []const u8,
    type: []const u8,
    volume_percent: ?u8,
    supports_volume: ?bool = null,
};

pub fn get(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, additional_types: ?[]const u8 = null },
) !JsonResponse(?Self) {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player",
        null,
        .{ .market = opts.market, .additional_types = opts.additional_types },
    );
    defer alloc.free(player_url);

    var request = try client.get(alloc, try std.Uri.parse(player_url));
    defer request.deinit();
    return JsonResponse(?Self).parse(alloc, &request);
}

pub fn getDevices(
    alloc: std.mem.Allocator,
    client: anytype,
) !JsonResponse(M(Device, "devices")) {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/devices",
        null,
        .{},
    );
    defer alloc.free(player_url);

    var request = try client.get(alloc, try std.Uri.parse(player_url));
    defer request.deinit();
    return JsonResponse(M(Device, "devices")).parse(alloc, &request);
}

pub fn currentlyPlaying(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        markets: ?[]const u8 = null,
        additional_types: ?[]const u8 = null,
    },
) !JsonResponse(?Self) {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/currently-playing",
        null,
        .{ .markets = opts.markets, .additional_types = opts.additional_types },
    );
    defer alloc.free(player_url);

    var request = try client.get(alloc, try std.Uri.parse(player_url));
    defer request.deinit();
    return JsonResponse(?Self).parse(alloc, &request);
}

pub fn play(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/play",
        null,
        .{ .device_id = @as(?[]const u8, device_id) },
    );
    defer alloc.free(player_url);
    var request = try client.put(alloc, try std.Uri.parse(player_url), .{ .position_ms = 0 });
    defer request.deinit();
}

pub fn pause(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/pause",
        null,
        .{ .device_id = @as(?[]const u8, device_id) },
    );
    defer alloc.free(player_url);

    var request = try client.put(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

pub fn next(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/next",
        null,
        .{ .device_id = @as(?[]const u8, device_id) },
    );
    defer alloc.free(player_url);

    var request = try client.post(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

pub fn previous(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/previous",
        null,
        .{ .device_id = @as(?[]const u8, device_id) },
    );
    defer alloc.free(player_url);

    var request = try client.post(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

// https://developer.spotify.com/documentation/web-api/reference/seek-to-position-in-currently-playing-track
// /seek?device_id=...&position_ms=integer
pub fn seekTo(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
    position_ms: usize,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/seek",
        null,
        .{
            .device_id = @as(?[]const u8, device_id),
            .position_ms = @as(?usize, position_ms),
        },
    );
    defer alloc.free(player_url);

    var request = try client.put(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

// https://developer.spotify.com/documentation/web-api/reference/set-repeat-mode-on-users-playback
pub fn setRepeat(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
    state: enum { track, context, off },
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/repeat",
        null,
        .{
            .device_id = @as(?[]const u8, device_id),
            .state = @as(?[]const u8, @tagName(state)),
        },
    );
    defer alloc.free(player_url);

    var request = try client.put(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

// https://developer.spotify.com/documentation/web-api/reference/set-volume-for-users-playback
// /volume?device_id=...&volume_percent=(0-100)
pub fn setVolume(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
    volume_percent: u8,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/volume",
        null,
        .{
            .device_id = @as(?[]const u8, device_id),
            .volume_percent = @as(?u8, volume_percent),
        },
    );
    defer alloc.free(player_url);

    var request = try client.put(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}

// https://developer.spotify.com/documentation/web-api/reference/toggle-shuffle-for-users-playback
// /shuffle?device_id=...&state=true|false
pub fn setShuffle(
    alloc: std.mem.Allocator,
    client: anytype,
    device_id: []const u8,
    shuffle: bool,
) !void {
    const player_url = try url.build(
        alloc,
        url.base_url,
        "/me/player/shuffle",
        null,
        .{
            .device_id = @as(?[]const u8, device_id),
            .state = @as(?bool, shuffle),
        },
    );
    defer alloc.free(player_url);

    var request = try client.put(alloc, try std.Uri.parse(player_url), .{});
    defer request.deinit();
}
