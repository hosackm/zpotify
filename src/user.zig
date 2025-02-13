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

pub const CursoredArtists = struct { artists: types.Cursored(Artist) };
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
