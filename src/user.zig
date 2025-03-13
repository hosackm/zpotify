//! This module contains definitions and methods for interacting with
//! User resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");

const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");
const Client = @import("client.zig").Client;

const Simple = struct {
    // The name displayed on the user's profile. null if not available.
    display_name: ?[]const u8,
    // Known external URLs for this user.
    external_urls: std.json.Value,
    // Information about the followers of the user.
    followers: std.json.Value,
    // A link to the Web API endpoint for this user.
    href: []const u8,
    // The Spotify user ID for the user.
    id: types.SpotifyId,
    // The user's profile image.
    images: []const Image,
    // The object type: "user"
    type: []const u8,
    // The Spotify URI for the user.
    uri: types.SpotifyUri,
};

// Import the Simple namespace and extend it
pub usingnamespace Simple;

// The country of the user, as set in the user's account profile. An ISO 3166-1
// alpha-2 country code. This field is only available when the current user has
// granted access to the user-read-private scope.
country: []const u8,
// The user's email address, as entered by the user when creating their account.
// Important! This email address is unverified; there is no proof that it actually
// belongs to the user. This field is only available when the current user has
//granted access to the user-read-email scope.
email: []const u8,
// The user's explicit content settings. This field is only available when the current
// user has granted access to the user-read-private scope.
explicit_content: std.json.Value,
// The user's Spotify subscription level: "premium", "free", etc.
// (The subscription level "open" can be considered the same as "free".) This field is
//only available when the current user has granted access to the user-read-private scope.
product: []const u8,

const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;
const User = @This();

// Get detailed profile information about the current user (including the current user's username).
// https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile
pub fn getCurrentUser(
    alloc: std.mem.Allocator,
    client: *Client,
) !JsonResponse(User) {
    var request = try client.get(alloc, try std.Uri.parse(url.base_url ++ "/me"));
    defer request.deinit();
    return JsonResponse(User).parseRequest(alloc, &request);
}

// Structure used to represent top artists or tracks
const Top = union(enum) {
    artists: struct {},
    tracks: struct {},
};

// Enumeration of acceptable time_range values
const TimeRange = enum { short_term, medium_term, long_term };

// Get the current user's top artists based on calculated affinity.
// https://developer.spotify.com/documentation/web-api/reference/get-users-top-artists-and-tracks
// opts.time_range - optional time range on which to base "top" calculations.
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn topArtists(
    alloc: std.mem.Allocator,
    client: *Client,
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
    return JsonResponse(Paged(Artist)).parseRequest(alloc, &request);
}

// Get the current user's top tracks based on calculated affinity.
// https://developer.spotify.com/documentation/web-api/reference/get-users-top-artists-and-tracks
// opts.time_range - optional time range on which to base "top" calculations.
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn topTracks(
    alloc: std.mem.Allocator,
    client: *Client,
    opts: struct {
        time_range: ?TimeRange = null,
        limit: ?u8 = null,
        offset: ?u8 = null,
    },
) !JsonResponse(Paged(Track.Simple)) {
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
    return JsonResponse(Paged(Track.Simple)).parseRequest(alloc, &request);
}

// Get public profile information about a Spotify user.
// https://developer.spotify.com/documentation/web-api/reference/get-users-profile
//
// user_id - The Spotify User ID to retrieve
pub fn get(
    alloc: std.mem.Allocator,
    client: *Client,
    user_id: types.SpotifyUserId,
) !JsonResponse(Simple) {
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
    return JsonResponse(Simple).parseRequest(alloc, &request);
}

// Add the current user as a follower of a playlist.
// https://developer.spotify.com/documentation/web-api/reference/follow-playlist
//
// playlist_id - the Spotify Playlist ID to follow
// opts.public - Defaults to true. If true the playlist will be included in user's
//               public playlists (added to profile), if false it will remain private.
pub fn followPlaylist(
    alloc: std.mem.Allocator,
    client: *Client,
    playlist_id: types.SpotifyId,
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

// Remove the current user as a follower of a playlist.
// https://developer.spotify.com/documentation/web-api/reference/unfollow-playlist
//
// playlist_id - the Spotify Playlist ID to follow
pub fn unfollowPlaylist(
    alloc: std.mem.Allocator,
    client: *Client,
    playlist_id: types.SpotifyId,
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

// Check to see if the current user is following a specified playlist.
// https://developer.spotify.com/documentation/web-api/reference/check-if-user-follows-playlist
//
// playlist_id - the Spotify Playlist ID the user may be following
// Returns a slice of bools with one value for backwards compatability reasons.
pub fn isFollowingPlaylist(
    alloc: std.mem.Allocator,
    client: *Client,
    playlist_id: types.SpotifyId,
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
    return JsonResponse([]bool).parseRequest(alloc, &request);
}

pub const CursoredArtists = struct { artists: types.Cursored(Artist) };

// Get the current user's followed artists.
// https://developer.spotify.com/documentation/web-api/reference/get-followed
//
// opts.after - The last artist ID retrieved from the previous request.
// opts.limit - The maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
pub fn getFollowedArtists(
    alloc: std.mem.Allocator,
    client: *Client,
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
    return JsonResponse(CursoredArtists).parseRequest(alloc, &request);
}

// Add the current user as a follower of an artist.
// https://developer.spotify.com/documentation/web-api/reference/follow-artists-users
//
// id - Spotify Artist ID to follow
pub fn followArtist(alloc: std.mem.Allocator, client: *Client, id: types.SpotifyId) !void {
    try followArtists(alloc, client, &.{id});
}

// Add the current user as a follower of one or more artists.
// https://developer.spotify.com/documentation/web-api/reference/follow-artists-users
//
// ids - Spotify Artist IDs to follow
pub fn followArtists(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Remove the current user as a follower of an artist.
// https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users
//
// id - Spotify Artist ID to unfollow
pub fn unfollowArtist(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
) !void {
    try unfollowArtists(alloc, client, &.{id});
}

// Remove the current user as a follower of one or more artists.
// https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users
//
// ids - Spotify Artist IDs to un follow
pub fn unfollowArtists(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Add the current user as a follower a user.
// https://developer.spotify.com/documentation/web-api/reference/follow-artists-users
//
// id - Spotify User ID to follow
pub fn followUser(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
) !void {
    try followUsers(alloc, client, &.{id});
}

// Add the current user as a follower of one or other users.
// https://developer.spotify.com/documentation/web-api/reference/follow-artists-users
//
// ids - Spotify User IDs to follow
pub fn followUsers(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Remove the current user as a follower of a user.
// https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users
//
// id - Spotify User ID to unfollow
pub fn unfollowUser(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
) !void {
    try unfollowUsers(alloc, client, &.{id});
}

// Remove the current user as a follower of one or other users.
// https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users
//
// ids - Spotify User IDs to unfollow
pub fn unfollowUsers(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Check to see if the current user is following one or more other Spotify Artists.
// https://developer.spotify.com/documentation/web-api/reference/check-current-user-follows
//
// ids - Spotify Artist IDs to check if current user is following
pub fn isFollowingArtists(
    alloc: std.mem.Allocator,
    client: *Client,
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
    return JsonResponse([]bool).parseRequest(alloc, &request);
}

// Check to see if the current user is following one or more other Spotify users.
// https://developer.spotify.com/documentation/web-api/reference/check-current-user-follows
//
// ids - Spotify User IDs to check if current user is following
pub fn isFollowingUsers(
    alloc: std.mem.Allocator,
    client: *Client,
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
    return JsonResponse([]bool).parseRequest(alloc, &request);
}
