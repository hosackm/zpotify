//! Playlists from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Track = @import("track.zig");
const Paged = types.Paginated;
const P = std.json.Parsed;
const M = types.Manyify;

const Self = @This();

pub const PlaylistTrack = struct {
    added_at: []const u8,
    added_by: ?std.json.Value,
    is_local: bool,
    // track: track or episode
};

pub const Details = struct {
    name: ?[]const u8 = null,
    public: ?bool = null,
    collaborative: ?bool = null,
    description: ?[]const u8 = null,
};

pub const Insert = struct {
    uris: ?[]const types.SpotifyUri = null,
    range_start: ?u16 = null,
    insert_before: ?u16 = null,
    range_length: ?u16 = null,
    snapshot_id: ?[]const u8 = null,
};

pub const Add = struct {
    uris: ?[]const types.SpotifyUri,
    position: ?u16,
};

pub const Remove = struct {
    tracks: ?[]const types.SpotifyUri = null,
    snapshot_id: ?[]const u8 = null,
};

collaborative: bool,
description: []const u8,
external_urls: std.json.Value,
followers: std.json.Value,
href: []const u8,
id: []const u8,
images: []const Image,
name: []const u8,
owner: std.json.Value,
public: bool,
// primary_color: ?[]const u8,
snapshot_id: []const u8,
tracks: Paged(PlaylistTrack),
type: []const u8,
uri: types.SpotifyUri,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        additional_types: ?[]const u8 = null,
    },
) !P(Self) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn setDetails(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    details: Details,
) !void {
    _ = details;
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
        additional_types: ?[]const u8 = null,
    },
) !P(Paged(PlaylistTrack)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(PlaylistTrack),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn update(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    insert: Insert,
) !P(Paged(PlaylistTrack)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = insert;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(PlaylistTrack),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn add(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    info: Add,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = info;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    rem: Remove,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = rem;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
