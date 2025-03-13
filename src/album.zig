//! This module contains definitions and methods for interacting with
//! Album resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");
const Client = @import("client.zig").Client;

// Simplified album representation used when included in
// another data type returned by the web api.
pub const Simple = struct {
    // The type of the album: Allowed values: "album", "single", "compilation"
    album_type: []const u8,
    // The number of tracks in the album.
    total_tracks: usize,
    // The markets in which the album is available: ISO 3166-1 alpha-2 country codes.
    available_markets: []const []const u8,
    // The cover art for the album in various sizes, widest first.
    images: []const Image,
    // The name of the album. In case of an album takedown, the value may be an empty string.
    name: []const u8,
    // The date the album was first released.
    release_date: []const u8,
    // The precision with which release_date value is known.
    // Allowed values: "year", "month", "day"
    release_date_precision: []const u8,
    // The artists of the album. Each artist object includes a link in href
    // to more detailed information about the artist.
    artists: []const Artist.Simple,
    // Known external URLs for this album.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the album.
    href: []const u8,
    // The Spotify ID for the album.
    id: types.SpotifyId,
    // The object type, ie: "album"
    type: []const u8,
    // The Spotify URI for the album.
    uri: types.SpotifyUri,
};

// Include and expand on the Simple namespace.
pub usingnamespace Simple;

// The copyright statements of the album.
copyrights: []const struct { text: []const u8, type: []const u8 },
// Deprecated The array is always empty.
genres: []const u8,
// The popularity of the album. The value will be between 0 and 100,
// with 100 being the most popular.
popularity: u8,
// The tracks of the album.
tracks: Paged(Track.Simple),
// Known external IDs for the album.
external_ids: ?std.json.Value = null,
// The label associated with the album.
label: ?[]const u8 = null,
// Included in the response when a content restriction is applied.
restrictions: ?std.json.Value = null,
album_group: ?[]const u8 = null,

const Self = @This();
pub const Paged = types.Paginated;
const JsonResponse = types.JsonResponse;
const M = types.Manyify;

// Get Spotify catalog information for a single album.
// https://developer.spotify.com/documentation/web-api/reference/get-an-album
//
// id - a Spotify Album ID ie. "4aawyAB9vmqN3uQ7FjRGTy"
// opts.market - an optional ISO 3166-1 Country Code
pub fn getOne(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(Self).parseRequest(alloc, &request);
}

// Get Spotify catalog information for multiple albums identified by their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-multiple-albums
//
// ids - Spotify Album IDs ie. "382ObEPsp2rxGrnsizN5TX","1A2GTWGtFfWp7KSQTwWOyo","2noRn2Aes5aoNVsU6iWThc"
// opts - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Self, "albums")) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(M(Self, "albums")).parseRequest(alloc, &request);
}

// Get Spotify catalog information about an album’s tracks. Optional parameters can
// be used to limit the number of tracks returned.
// https://developer.spotify.com/documentation/web-api/reference/get-an-albums-tracks
//
// id - a Spotify Album ID ie. "4aawyAB9vmqN3uQ7FjRGTy"
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getTracks(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Track.Simple)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}/tracks",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(Paged(Track.Simple)).parseRequest(alloc, &request);
}

// User's saved album representation.
pub const Saved = struct {
    // The date and time the album was saved Timestamps are returned in ISO 8601
    added_at: []const u8,
    // Information about the album.
    album: Self,
};

// Get a list of the albums saved in the current Spotify user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/get-users-saved-albums
//
// id - a Spotify Album ID ie. "4aawyAB9vmqN3uQ7FjRGTy"
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: *Client,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parseRequest(alloc, &request);
}

// Save one or more albums to the current user's 'Your Music' library.
//
// https://developer.spotify.com/documentation/web-api/reference/save-albums-user
//
// ids - Spotify Album IDs to save, ie: &.{"4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"}
pub fn save(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    var req = try client.put(
        alloc,
        try std.Uri.parse(url.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer req.deinit();
}

// Remove one or more albums from the current user's 'Your Music' library.
//
// https://developer.spotify.com/documentation/web-api/reference/remove-albums-user
//
// ids - Spotify Album IDs to remove, ie: &.{"4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"}
pub fn remove(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    var req = try client.delete(
        alloc,
        try std.Uri.parse(url.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer req.deinit();
}

// Check if one or more albums is already saved in the current
// Spotify user's 'Your Music' library. Returns a slice of bools.
//
// https://developer.spotify.com/documentation/web-api/reference/check-users-saved-albums
//
// ids - Spotify Album IDs to remove, ie: &.{"4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"}
pub fn contains(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(album_url);

    var request = try client.get(alloc, try std.Uri.parse(album_url));
    defer request.deinit();
    return JsonResponse([]bool).parseRequest(alloc, &request);
}

pub const PagedSimpleAlbum = struct { albums: Paged(Simple) };

// Get a list of new album releases featured in Spotify (shown, for example,
// on a Spotify player’s “Browse” tab).  Returns a slice of Simple Albums.
//
// https://developer.spotify.com/documentation/web-api/reference/get-new-releases
//
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn newReleases(
    alloc: std.mem.Allocator,
    client: *Client,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(PagedSimpleAlbum) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/browse/new-releases",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(alloc, try std.Uri.parse(album_url));
    defer request.deinit();
    return JsonResponse(PagedSimpleAlbum).parseRequest(alloc, &request);
}
