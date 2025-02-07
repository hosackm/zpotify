//! Track from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Artist = @import("artist.zig");
const Image = @import("image.zig");

const P = std.json.Parsed;
const M = types.Manyify;
const Paged = types.Paginated;

const Self = @This();

// Extend from Simplified
pub usingnamespace Simplified;

album: Album.Simplified,
external_ids: std.json.Value,
popularity: u8,

pub const Simplified = struct {
    artists: []const Artist.Simplified,
    available_markets: []const []const u8,
    disc_number: usize,
    duration_ms: usize,
    explicit: bool,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    is_local: bool,
    name: []const u8,
    preview_url: ?[]const u8,
    track_number: usize,
    type: []const u8,
    uri: types.SpotifyUri,
};

// missing
// linked_from: std.json.Value,
// restrictions: std.json.Value,
// missing often
// name: []const u8, // missing from albums/{id}/tracks
// popularity: u8,
// external_ids: std.json.Value,
// is_playable: bool,
// linked_from: std.json.Value,
// restrictions: std.json.Value,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(M(Simplified, "tracks")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        M(Simplified, "tracks"),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub const Saved = struct { added_at: []const u8, track: Simplified };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !P(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Saved),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);
    const body = try client.put(alloc, try std.Uri.parse(show_url), .{});
    defer alloc.free(body);
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);
    const body = try client.delete(alloc, try std.Uri.parse(show_url), .{});
    defer alloc.free(body);
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    const body = try client.get(alloc, try std.Uri.parse(show_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
