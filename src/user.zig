//! Users from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");

const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;

const Simplified = struct {
    display_name: []const u8,
    external_urls: std.json.Value,
    followers: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    images: []const Image,
    type: []const u8,
    uri: types.SpotifyUri,
};

pub usingnamespace Simplified;

country: []const u8,
email: []const u8,
explicit_content: std.json.Value,
product: []const u8,

const User = @This();

pub fn getCurrentUser(
    alloc: std.mem.Allocator,
    client: anytype,
) !P(User) {
    const body = try client.get(
        alloc,
        try std.Uri.parse(url.base_url ++ "/me"),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        User,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const Top = union(enum) {
    artists: struct {},
    tracks: struct {},
};

const Which = enum { artists, tracks };
const TimeRange = enum { short_term, medium_term, long_term };

pub fn topArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !P(Paged(Artist)) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/top/artists",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(user_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(user_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Artist),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn topTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !P(Paged(Track.Simplified)) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/top/tracks",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(user_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(user_url),
    );
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        Paged(Track.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn get(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime user_id: types.SpotifyUserId,
) !P(Simplified) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/users/{s}",
        user_id,
        .{},
    );
    defer alloc.free(user_url);

    const body = try client.get(alloc, try std.Uri.parse(user_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Simplified,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn followPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime playlist_id: types.SpotifyId,
    opts: struct { public: ?bool = null },
) !void {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/followers",
        playlist_id,
        .{ .public = opts.public },
    );
    defer alloc.free(user_url);

    const data: struct { public: bool } = .{ .public = opts.public orelse true };
    const body = try client.put(
        alloc,
        try std.Uri.parse(user_url),
        data,
    );
    defer alloc.free(body);
}

pub fn unfollowPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime playlist_id: types.SpotifyId,
) !void {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/followers",
        playlist_id,
        .{},
    );
    defer alloc.free(user_url);

    const body = try client.delete(alloc, try std.Uri.parse(user_url), .{});
    defer alloc.free(body);
}

pub fn isFollowingPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime playlist_id: types.SpotifyId,
) !bool {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/followers/contains",
        playlist_id,
        .{},
    );
    defer alloc.free(user_url);

    const body = try client.get(alloc, try std.Uri.parse(user_url));
    defer alloc.free(body);

    const object = try std.json.parseFromSlice([]bool, alloc, body, .{});
    defer object.deinit();

    const following: []bool = object.value;
    return following[0];
}

const CursoredArtists = struct { artists: types.Cursored(Artist) };
pub fn getFollowedArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        after: ?[]const u8 = null,
        limit: ?u8 = null,
    },
) !P(CursoredArtists) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "artist"), .after = opts.after, .limit = opts.limit },
    );
    defer alloc.free(user_url);
    const body = try client.get(alloc, try std.Uri.parse(user_url));
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        CursoredArtists,
        alloc,
        body,
        .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        },
    );
}

pub fn followArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "artist") },
    );
    defer alloc.free(artist_url);

    const body = try client.put(
        alloc,
        try std.Uri.parse(artist_url),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn unfollowArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "artist") },
    );
    defer alloc.free(artist_url);

    const body = try client.delete(
        alloc,
        try std.Uri.parse(artist_url),
        .{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn followUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "user") },
    );
    defer alloc.free(user_url);

    const body = try client.put(
        alloc,
        try std.Uri.parse(user_url),
        .{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn unfollowUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "user") },
    );
    defer alloc.free(user_url);

    const body = try client.delete(
        alloc,
        try std.Uri.parse(user_url),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn isFollowingArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/me/following/contains",
        null,
        .{ .ids = ids, .type = @as(?[]const u8, "artist") },
    );
    defer alloc.free(artist_url);

    const body = try client.get(alloc, try std.Uri.parse(artist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{},
    );
}

pub fn isFollowingUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following/contains",
        null,
        .{ .ids = ids, .type = @as(?[]const u8, "user") },
    );
    defer alloc.free(user_url);

    const body = try client.get(alloc, try std.Uri.parse(user_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{},
    );
}
