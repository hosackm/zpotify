//! This module contains definitions and methods for interacting with
//! Player resources from the Spotify Web API.
const std = @import("std");
const url = @import("url.zig");
const types = @import("types.zig");
const Client = @import("client.zig").Client;

// Unix Millisecond Timestamp when playback state was last changed
// (play, pause, skip, scrub, new song, etc.).
timestamp: usize,
// A Context Object. Can be null.
context: ?std.json.Value,
// Progress into the currently playing track or episode. Can be null.
progress_ms: usize,
// The object type of the currently playing item. Can be one of track,
// episode, ad or unknown.
currently_playing_type: []const u8,
// Allows to update the user interface based on which playback actions
// are available within the current context.
actions: std.json.Value,
// If something is currently playing, return true.
is_playing: bool,
// The device that is currently active.
device: ?Device = null,

pub const Device = struct {
    // The device ID. This ID is unique and persistent to some extent. However,
    // this is not guaranteed and any cached device_id should periodically be
    // cleared out and refetched as necessary.
    id: []const u8,
    // If this device is the currently active device.
    is_active: bool,
    // If this device is currently in a private session.
    is_private_session: ?bool = null,
    // Whether controlling this device is restricted. At present if this is "true"
    // then no Web API commands will be accepted by this device.
    is_restricted: ?bool = null,
    // A human-readable name for the device. Some devices have a name that the user
    // can configure (e.g. "Loudest speaker") and some devices have a generic name
    // associated with the manufacturer or device model.
    name: []const u8,
    // Device type, such as "computer", "smartphone" or "speaker".
    type: []const u8,
    // The current volume in percent.
    volume_percent: ?u8,
    // If this device can be used to set the volume.
    supports_volume: ?bool = null,
};

// not returned in json when testing
// off, track, context
// repeat_state: ?[]const u8 = null,
// item: ?track or episod = null
// If shuffle is on or off.
// shuffle_state: ?bool = null,

const Self = @This();
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

// Get information about the user’s current playback state, including track
// or episode, progress, and active device.
// https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
//
// opts.market - an optional ISO 3166-1 Country Code
// opts.additional_types - A comma-separated list of item types that your client supports besides
//                         the default track type. Valid types are: track and episode.
pub fn get(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Get information about a user’s available Spotify Connect devices. Some device models
// are not supported and will not be listed in the API response.
// https://developer.spotify.com/documentation/web-api/reference/get-a-users-available-devices
//
pub fn getDevices(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Get the object currently being played on the user's Spotify account.
// https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track
//
// opts.market - an optional ISO 3166-1 Country Code
// opts.additional_types - A comma-separated list of item types that your client supports besides
//                         the default track type. Valid types are: track and episode.
pub fn currentlyPlaying(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Start a new context or resume current playback on the user's active device. This API only
// works for users who have Spotify Premium. The order of execution is not guaranteed when
// you use this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback
pub fn play(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Pause playback on the user's account. This API only works for users who have
// Spotify Premium. The order of execution is not guaranteed when you use this
// API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
pub fn pause(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Skips to next track in the user’s queue. This API only works for users who
// have Spotify Premium. The order of execution is not guaranteed when you use
// this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-next-track
pub fn next(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Skips to previous track in the user’s queue. This API only works for users who have
// Spotify Premium. The order of execution is not guaranteed when you use this API with
// other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-previous-track
pub fn previous(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Seeks to the given position in the user’s currently playing track. This
// API only works for users who have Spotify Premium. The order of execution
// is not guaranteed when you use this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/seek-to-position-in-currently-playing-track
pub fn seekTo(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Set the repeat mode for the user's playback. This API only works for users
// who have Spotify Premium. The order of execution is not guaranteed when
// you use this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/set-repeat-mode-on-users-playback
pub fn setRepeat(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Set the volume for the user’s current playback device. This API only works
// for users who have Spotify Premium. The order of execution is not guaranteed
// when you use this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/set-volume-for-users-playback
pub fn setVolume(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Toggle shuffle on or off for user’s playback. This API only works for users
// who have Spotify Premium. The order of execution is not guaranteed when you
// use this API with other Player API endpoints.
// https://developer.spotify.com/documentation/web-api/reference/toggle-shuffle-for-users-playback
pub fn setShuffle(
    alloc: std.mem.Allocator,
    client: *Client,
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
