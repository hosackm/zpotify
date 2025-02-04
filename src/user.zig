//! Users from the web API reference
const std = @import("std");
const types = @import("types.zig");
const urls = @import("urls.zig");

const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");

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
) !std.json.Parsed(User) {
    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me"),
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
        // which: Which,
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !std.json.Parsed(types.Paginated(Artist)) {
    _ = opts;
    const body = try client.get(
        alloc,
        try std.Uri.parse(
            urls.base_url ++ "/me/top/artists",
        ),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Artist),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn topTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        // which: Which,
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !std.json.Parsed(types.Paginated(Track.Simplified)) {
    _ = opts;
    const body = try client.get(
        alloc,
        try std.Uri.parse(
            urls.base_url ++ "/me/top/tracks",
        ),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Track.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn get(
    alloc: std.mem.Allocator,
    client: anytype,
    user_id: types.SpotifyUserId,
) !std.json.Parsed(Simplified) {
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/users/{s}",
        .{user_id},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
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
    playlist_id: types.SpotifyId,
    opts: struct { public: ?bool = null },
) !void {
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/playlists/{s}/followers",
        .{playlist_id},
    );
    defer alloc.free(url);

    // plug this in
    const data: struct { public: bool } = .{
        .public = opts.public orelse true,
    };

    const body = try client.put(
        alloc,
        try std.Uri.parse(url),
        data,
    );
    defer alloc.free(body);
}

pub fn unfollowPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    playlist_id: types.SpotifyId,
) !void {
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/playlists/{s}/followers",
        .{playlist_id},
    );
    defer alloc.free(url);

    const body = try client.delete(alloc, try std.Uri.parse(url), .{});
    defer alloc.free(body);
}

pub fn isFollowingPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    playlist_id: types.SpotifyId,
) !bool {
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/playlists/{s}/followers/contains",
        .{playlist_id},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
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
) !std.json.Parsed(CursoredArtists) {
    _ = opts;
    const body = try client.get(
        alloc,
        try std.Uri.parse(
            urls.base_url ++ "/me/following?type=artist",
        ),
    );
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
    const body = try client.put(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/following?type=artist"),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn unfollowArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const body = try client.delete(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/following?type=artist"),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn followUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const body = try client.put(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/following?type=user"),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn unfollowUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const body = try client.delete(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/following?type=user"),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn isFollowingArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed([]bool) {
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/me/following/contains?type=artist&ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
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
) !std.json.Parsed([]bool) {
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/me/following/contains?type=user&ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{},
    );
}
