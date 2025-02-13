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
const JsonResponse = types.JsonResponse;

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
) !JsonResponse(User) {
    var request = try client.get(alloc, try std.Uri.parse(url.base_url ++ "/me"));
    defer request.deinit();
    return JsonResponse(User).parse(alloc, &request);
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
) !JsonResponse(Paged(Artist)) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/top/artists",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();
    return JsonResponse(Paged(Artist)).parse(alloc, &request);
}

pub fn topTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !JsonResponse(Paged(Track.Simplified)) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/top/tracks",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();
    return JsonResponse(Paged(Track.Simplified)).parse(alloc, &request);
}

pub fn get(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime user_id: types.SpotifyUserId,
) !JsonResponse(Simplified) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/users/{s}",
        user_id,
        .{},
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();
    return JsonResponse(Simplified).parse(alloc, &request);
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
    var request = try client.put(alloc, try std.Uri.parse(user_url), data);
    defer request.deinit();
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

    var request = try client.delete(alloc, try std.Uri.parse(user_url), .{});
    defer request.deinit();
}

pub fn isFollowingPlaylist(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime playlist_id: types.SpotifyId,
) !JsonResponse([]bool) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/followers/contains",
        playlist_id,
        .{},
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();

    return JsonResponse([]bool).parse(alloc, &request);
}

const CursoredArtists = struct { artists: types.Cursored(Artist) };
pub fn getFollowedArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        after: ?[]const u8 = null,
        limit: ?u8 = null,
    },
) !JsonResponse(CursoredArtists) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following",
        null,
        .{ .type = @as(?[]const u8, "artist"), .after = opts.after, .limit = opts.limit },
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();
    return JsonResponse(CursoredArtists).parse(alloc, &request);
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

    var request = try client.put(
        alloc,
        try std.Uri.parse(artist_url),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer request.deinit();
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

    var request = try client.delete(alloc, try std.Uri.parse(artist_url), .{ .ids = ids });
    defer request.deinit();
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

    var request = try client.put(alloc, try std.Uri.parse(user_url), .{ .ids = ids });
    defer request.deinit();
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

    var request = try client.delete(
        alloc,
        try std.Uri.parse(user_url),
        struct { ids: @TypeOf(ids) }{ .ids = ids },
    );
    defer request.deinit();
}

pub fn isFollowingArtists(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/me/following/contains",
        null,
        .{ .ids = ids, .type = @as(?[]const u8, "artist") },
    );
    defer alloc.free(artist_url);

    var request = try client.get(alloc, try std.Uri.parse(artist_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}

pub fn isFollowingUsers(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const user_url = try url.build(
        alloc,
        url.base_url,
        "/me/following/contains",
        null,
        .{ .ids = ids, .type = @as(?[]const u8, "user") },
    );
    defer alloc.free(user_url);

    var request = try client.get(alloc, try std.Uri.parse(user_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}

test "parse user's top artists" {
    const artists = try std.json.parseFromSlice(
        Paged(Artist),
        std.testing.allocator,
        @import("test_data/files.zig").current_users_top_artists,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artists.deinit();
}

test "parse user's top tracks" {
    const tracks = try std.json.parseFromSlice(
        Paged(Track.Simplified),
        std.testing.allocator,
        @import("test_data/files.zig").current_users_top_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

test "parse user" {
    const data =
        \\{
        \\"country": "string",
        \\"display_name": "string",
        \\"email": "string",
        \\"explicit_content": {
        \\  "filter_enabled": false,
        \\  "filter_locked": false
        \\},
        \\"external_urls": {
        \\  "spotify": "string"
        \\},
        \\"followers": {
        \\  "href": "string",
        \\  "total": 0
        \\},
        \\"href": "string",
        \\"id": "string",
        \\"images": [
        \\  {
        \\    "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
        \\    "height": 300,
        \\    "width": 300
        \\  }
        \\],
        \\"product": "string",
        \\"type": "string",
        \\"uri": "string"
        \\}
    ;
    const user = try std.json.parseFromSlice(
        @This(),
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer user.deinit();
}

test "parse user's followed artists" {
    const tracks = try std.json.parseFromSlice(
        CursoredArtists,
        std.testing.allocator,
        @import("test_data/files.zig").current_users_followed_artists,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}
